//
//  WatchRecoveryManager.swift
//  Runner
//
//  Created by Malcolm Lightbody on 23/05/2026.
//

import Foundation
import SwiftUI
import HealthKit
import WatchConnectivity

final class WatchRecoveryManager: NSObject, ObservableObject, WCSessionDelegate, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    static let shared = WatchRecoveryManager()

    enum Mode {
        case idle
        case workoutActive
        case recoveryRecording
        case sending
        case sent
        case queued
        case error
    }

    @Published var mode: Mode = .idle
    @Published var currentHeartRate: Double?
    @Published var statusMessage = "Ready"
    @Published var recoveryElapsedSeconds = 0

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var recoveryTimer: Timer?

    private var peakHr: Double?
    private var hr60: Double?
    private var hr120: Double?

    private override init() {
        super.init()

        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    var currentHeartRateText: String {
        if let hr = currentHeartRate {
            return "\(Int(hr.rounded())) bpm"
        }
        return "-- bpm"
    }

    var buttonTitle: String {
        switch mode {
        case .idle, .sent, .queued, .error:
            return "Start Workout"
        case .workoutActive:
            return "End Workout"
        case .recoveryRecording:
            return "Recording..."
        case .sending:
            return "Sending..."
        }
    }

    var isButtonDisabled: Bool {
        mode == .recoveryRecording || mode == .sending
    }

    func primaryButtonTapped() {
        switch mode {
        case .idle, .sent, .queued, .error:
            startWorkout()
        case .workoutActive:
            endWorkoutAndStartRecovery()
        default:
            break
        }
    }

    func requestPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "Health data unavailable"
            return
        }

        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            statusMessage = "Heart rate unavailable"
            return
        }

        healthStore.requestAuthorization(toShare: [], read: [heartRateType]) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.statusMessage = "Ready"
                } else {
                    self.statusMessage = "Health permission needed"
                    if let error = error {
                        print("HealthKit permission error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func startWorkout() {
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .unknown

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()

            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: config
            )

            session.delegate = self
            builder.delegate = self

            workoutSession = session
            workoutBuilder = builder

            peakHr = nil
            hr60 = nil
            hr120 = nil
            recoveryElapsedSeconds = 0

            let startDate = Date()
            session.startActivity(with: startDate)
            builder.beginCollection(withStart: startDate) { _, error in
                if let error = error {
                    print("Begin collection error: \(error.localizedDescription)")
                }
            }

            DispatchQueue.main.async {
                self.mode = .workoutActive
                self.statusMessage = "Workout active. End workout to record recovery."
            }
        } catch {
            DispatchQueue.main.async {
                self.mode = .error
                self.statusMessage = "Could not start workout"
            }
            print(error.localizedDescription)
        }
    }

    private func endWorkoutAndStartRecovery() {
        workoutSession?.end()
        startRecoveryRecording()
    }

    private func startRecoveryRecording() {
        DispatchQueue.main.async {
            self.mode = .recoveryRecording
            self.statusMessage = "Recover normally. Measuring for 2 minutes."
            self.recoveryElapsedSeconds = 0
        }

        recoveryTimer?.invalidate()

        recoveryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            DispatchQueue.main.async {
                self.recoveryElapsedSeconds += 1

                if let hr = self.currentHeartRate {
                    if self.peakHr == nil || hr > self.peakHr! {
                        self.peakHr = hr
                    }

                    if self.recoveryElapsedSeconds == 60 {
                        self.hr60 = hr
                    }

                    if self.recoveryElapsedSeconds >= 120 {
                        self.hr120 = hr
                        timer.invalidate()
                        self.finishRecoveryAndSend()
                    }
                }
            }
        }
    }

    private func finishRecoveryAndSend() {
        mode = .sending
        statusMessage = "Sending measurements..."

        let payload: [String: Any] = [
            "type": "fakeRecoverySession",
            "sessionId": UUID().uuidString,
            "peakHr": Int((peakHr ?? currentHeartRate ?? 0).rounded()),
            "hr60": Int((hr60 ?? currentHeartRate ?? 0).rounded()),
            "hr120": Int((hr120 ?? currentHeartRate ?? 0).rounded()),
            "timestamp": Date().timeIntervalSince1970
        ]

        let session = WCSession.default

        if session.activationState == .activated && session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                print("sendMessage failed: \(error.localizedDescription)")
                session.transferUserInfo(payload)

                DispatchQueue.main.async {
                    self.mode = .queued
                    self.statusMessage = "Phone unavailable. Saved for later."
                }
            }

            DispatchQueue.main.async {
                self.mode = .sent
                self.statusMessage = "Sent to iPhone. Open Pulse Recovery to review."
            }
        } else {
            session.transferUserInfo(payload)

            DispatchQueue.main.async {
                self.mode = .queued
                self.statusMessage = "Saved on Watch. Will send when iPhone is nearby."
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              collectedTypes.contains(heartRateType),
              let statistics = workoutBuilder.statistics(for: heartRateType),
              let quantity = statistics.mostRecentQuantity()
        else {
            return
        }

        let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let bpm = quantity.doubleValue(for: bpmUnit)

        DispatchQueue.main.async {
            self.currentHeartRate = bpm

            if self.mode == .workoutActive || self.mode == .recoveryRecording {
                if self.peakHr == nil || bpm > self.peakHr! {
                    self.peakHr = bpm
                }
            }
        }
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {}

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.mode = .error
            self.statusMessage = "Workout failed"
        }
        print(error.localizedDescription)
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}

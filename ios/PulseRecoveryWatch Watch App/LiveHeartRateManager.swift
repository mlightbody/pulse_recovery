import Foundation
import HealthKit
import SwiftUI
import WatchKit

final class LiveHeartRateManager: NSObject,
                                  ObservableObject,
                                  HKWorkoutSessionDelegate,
                                  HKLiveWorkoutBuilderDelegate {

    enum Mode {
        case idle
        case workoutActive
        case recoveryRecording
        case complete
        case error
    }

    struct HeartRateSample {
        let timestamp: Date
        let bpm: Double
        let phase: String
    }

    @Published var mode: Mode = .idle
    @Published var currentHeartRate: Double?
    @Published var statusMessage: String = "Ready"
    @Published var sampleCount: Int = 0
    @Published var recoveryElapsedSeconds: Int = 0
    @Published var debugMessages: [String] = ["App loaded"]

    @Published var endHr: Double?
    @Published var hr60: Double?
    @Published var hr120: Double?

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var recoveryTimer: Timer?

    private var workoutStartTime: Date?
    private var recoveryStartTime: Date?
    private var allSamples: [HeartRateSample] = []

    override init() {
        super.init()
        addDebug("Manager initialised")
    }

    var heartRateText: String {
        if let currentHeartRate {
            return "\(Int(currentHeartRate.rounded())) bpm"
        } else {
            return "-- bpm"
        }
    }

    var buttonTitle: String {
        switch mode {
        case .idle, .complete, .error:
            return "Start Workout"
        case .workoutActive:
            return "End Workout"
        case .recoveryRecording:
            return "Recording..."
        }
    }

    var isButtonDisabled: Bool {
        mode == .recoveryRecording
    }

    var hasRecoveryResult: Bool {
        endHr != nil || hr60 != nil || hr120 != nil
    }

    var endHrText: String {
        formatHr(endHr)
    }

    var hr60Text: String {
        formatHr(hr60)
    }

    var hr120Text: String {
        formatHr(hr120)
    }

    func primaryButtonPressed() {
        WKInterfaceDevice.current().play(.click)

        switch mode {
        case .idle, .complete, .error:
            addDebug("Start pressed")
            requestPermissionAndStartWorkout()

        case .workoutActive:
            addDebug("End workout pressed")
            beginRecoveryRecording()

        case .recoveryRecording:
            break
        }
    }

    private func requestPermissionAndStartWorkout() {
        addDebug("Checking HealthKit")

        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "Health data unavailable"
            addDebug("Health data unavailable")
            mode = .error
            return
        }

        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            statusMessage = "Heart rate unavailable"
            addDebug("HR type unavailable")
            mode = .error
            return
        }

        let workoutType = HKObjectType.workoutType()

        statusMessage = "Requesting Health permission..."
        addDebug("Requesting Health permission")

        healthStore.requestAuthorization(
            toShare: [workoutType],
            read: [heartRateType, workoutType]
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.addDebug("Permission processed")
                    self.startWorkout()
                } else {
                    self.statusMessage = "Health permission failed"
                    self.mode = .error
                    self.addDebug("Permission failed")

                    if let error {
                        self.addDebug("Permission error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .unknown

        do {
            let session = try HKWorkoutSession(
                healthStore: healthStore,
                configuration: configuration
            )

            let builder = session.associatedWorkoutBuilder()

            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            session.delegate = self
            builder.delegate = self

            workoutSession = session
            workoutBuilder = builder

            workoutStartTime = Date()
            recoveryStartTime = nil

            endHr = nil
            hr60 = nil
            hr120 = nil

            allSamples.removeAll()
            sampleCount = 0
            recoveryElapsedSeconds = 0
            currentHeartRate = nil

            statusMessage = "Starting workout..."
            addDebug("Starting workout")

            let startDate = Date()
            session.startActivity(with: startDate)

            builder.beginCollection(withStart: startDate) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.mode = .workoutActive
                        self.statusMessage = "Workout active"
                        self.addDebug("Collection started")
                    } else {
                        self.mode = .error
                        self.statusMessage = "Failed to collect HR"
                        self.addDebug("Collection failed")
                    }

                    if let error {
                        self.addDebug("Begin error: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.mode = .error
                self.statusMessage = "Could not start workout"
                self.addDebug("Workout start error: \(error.localizedDescription)")
            }
        }
    }

    private func beginRecoveryRecording() {
        endHr = currentHeartRate
        recoveryStartTime = Date()
        recoveryElapsedSeconds = 0
        hr60 = nil
        hr120 = nil

        mode = .recoveryRecording
        statusMessage = "Recover normally. Measuring 2 minutes."

        if let endHr {
            addDebug("End HR: \(Int(endHr.rounded()))")
        } else {
            addDebug("End HR unavailable")
        }

        recoveryTimer?.invalidate()

        recoveryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            DispatchQueue.main.async {
                self.recoveryElapsedSeconds += 1

                if self.recoveryElapsedSeconds == 60 {
                    self.hr60 = self.currentHeartRate
                    if let hr60 = self.hr60 {
                        self.addDebug("HR60: \(Int(hr60.rounded()))")
                    } else {
                        self.addDebug("HR60 unavailable")
                    }
                }

                if self.recoveryElapsedSeconds >= 120 {
                    self.hr120 = self.currentHeartRate
                    if let hr120 = self.hr120 {
                        self.addDebug("HR120: \(Int(hr120.rounded()))")
                    } else {
                        self.addDebug("HR120 unavailable")
                    }

                    timer.invalidate()
                    self.finishRecoverySession()
                }
            }
        }
    }

    private func finishRecoverySession() {
        mode = .complete
        statusMessage = "Recovery complete"
        addDebug("Recovery complete")
        addDebug("Total samples: \(allSamples.count)")
        endHealthKitWorkout()
    }

    private func endHealthKitWorkout() {
        addDebug("Ending HealthKit workout")
        workoutSession?.end()
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        addDebug("Workout event")
    }

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
            self.sampleCount += 1

            let phase = self.mode == .recoveryRecording ? "recovery" : "workout"

            self.allSamples.append(
                HeartRateSample(
                    timestamp: Date(),
                    bpm: bpm,
                    phase: phase
                )
            )

            if self.mode == .workoutActive {
                self.statusMessage = "Workout active"
            } else if self.mode == .recoveryRecording {
                self.statusMessage = "Recording recovery"
            }

            self.addDebug("HR \(self.sampleCount): \(Int(bpm.rounded()))")
        }
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        DispatchQueue.main.async {
            switch toState {
            case .running:
                self.addDebug("Workout running")

            case .ended:
                self.addDebug("Workout ended")

                self.workoutBuilder?.endCollection(withEnd: Date()) { _, error in
                    DispatchQueue.main.async {
                        if let error {
                            self.addDebug("End collection error: \(error.localizedDescription)")
                        } else {
                            self.addDebug("Collection ended")
                        }

                        self.workoutBuilder?.finishWorkout { workout, error in
                            DispatchQueue.main.async {
                                if let error {
                                    self.addDebug("Finish error: \(error.localizedDescription)")
                                } else if workout != nil {
                                    self.addDebug("Workout saved")
                                } else {
                                    self.addDebug("Workout finished")
                                }
                            }
                        }
                    }
                }

            case .paused:
                self.addDebug("Workout paused")

            case .prepared:
                self.addDebug("Workout prepared")

            case .notStarted:
                self.addDebug("Workout not started")

            @unknown default:
                self.addDebug("Workout unknown")
            }
        }
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.mode = .error
            self.statusMessage = "Workout failed"
            self.addDebug("Workout failed: \(error.localizedDescription)")
        }
    }

    private func formatHr(_ hr: Double?) -> String {
        if let hr {
            return "\(Int(hr.rounded())) bpm"
        } else {
            return "--"
        }
    }

    private func addDebug(_ message: String) {
        let timestamp = Self.shortTimeString()
        let line = "\(timestamp) \(message)"

        if Thread.isMainThread {
            debugMessages.insert(line, at: 0)

            if debugMessages.count > 8 {
                debugMessages.removeLast()
            }
        } else {
            DispatchQueue.main.async {
                self.debugMessages.insert(line, at: 0)

                if self.debugMessages.count > 8 {
                    self.debugMessages.removeLast()
                }
            }
        }
    }

    private static func shortTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}

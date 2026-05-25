import Foundation
import HealthKit
import SwiftUI
import WatchKit

final class LiveHeartRateManager: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {

    @Published var currentHeartRate: Double?
    @Published var statusMessage: String = "Ready"
    @Published var sampleCount: Int = 0
    @Published var isWorkoutRunning: Bool = false
    @Published var buttonTapCount: Int = 0
    @Published var debugMessages: [String] = ["App loaded"]

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

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
        if isWorkoutRunning {
            return "Stop HR Test"
        } else {
            return "Start HR Test #\(buttonTapCount)"
        }
    }

    func buttonPressed() {
        buttonTapCount += 1
        WKInterfaceDevice.current().play(.click)

        statusMessage = "Button pressed #\(buttonTapCount)"
        addDebug("Button pressed #\(buttonTapCount)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.isWorkoutRunning {
                self.stopWorkout()
            } else {
                self.requestPermissionAndStart()
            }
        }
    }

    private func requestPermissionAndStart() {
        addDebug("Checking HealthKit availability")

        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "Health data not available"
            addDebug("Health data not available")
            return
        }

        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            statusMessage = "Heart rate type unavailable"
            addDebug("Heart rate type unavailable")
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
                    let heartRateStatus = self.healthStore.authorizationStatus(for: heartRateType)
                    let workoutStatus = self.healthStore.authorizationStatus(for: workoutType)

                    self.addDebug("HR auth: \(heartRateStatus.rawValue)")
                    self.addDebug("Workout auth: \(workoutStatus.rawValue)")

                    self.statusMessage = "Health permission processed"
                    self.startWorkout()
                } else {
                    self.statusMessage = "Health permission failed"
                    self.addDebug("Health permission failed")

                    if let error {
                        self.addDebug("Permission error: \(error.localizedDescription)")
                        print("HealthKit permission error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func startWorkout() {
        addDebug("Creating workout config")

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

            sampleCount = 0
            currentHeartRate = nil
            statusMessage = "Starting workout..."
            addDebug("Starting workout session")

            let startDate = Date()

            session.startActivity(with: startDate)

            builder.beginCollection(withStart: startDate) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.isWorkoutRunning = true
                        self.statusMessage = "Workout running. Waiting for HR..."
                        self.addDebug("Collection started")
                    } else {
                        self.statusMessage = "Failed to collect HR"
                        self.addDebug("Collection failed")
                    }

                    if let error {
                        self.addDebug("Begin error: \(error.localizedDescription)")
                        print("Begin collection error: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.statusMessage = "Could not start workout"
                self.isWorkoutRunning = false
                self.addDebug("Workout start error: \(error.localizedDescription)")
            }

            print("Workout start error: \(error.localizedDescription)")
        }
    }

    func stopWorkout() {
        statusMessage = "Stopping workout..."
        addDebug("Stopping workout")

        workoutSession?.end()
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        addDebug("Workout event collected")
    }

    func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              collectedTypes.contains(heartRateType) else {
            DispatchQueue.main.async {
                self.addDebug("Data collected, but not HR")
            }
            return
        }

        guard let statistics = workoutBuilder.statistics(for: heartRateType),
              let quantity = statistics.mostRecentQuantity() else {
            DispatchQueue.main.async {
                self.addDebug("HR collected, no quantity yet")
            }
            return
        }

        let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let bpm = quantity.doubleValue(for: bpmUnit)

        DispatchQueue.main.async {
            self.currentHeartRate = bpm
            self.sampleCount += 1
            self.statusMessage = "Receiving heart-rate samples"
            self.addDebug("HR sample \(self.sampleCount): \(Int(bpm.rounded())) bpm")
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
            case .notStarted:
                self.addDebug("Workout state: not started")

            case .prepared:
                self.addDebug("Workout state: prepared")

            case .running:
                self.statusMessage = "Workout running"
                self.isWorkoutRunning = true
                self.addDebug("Workout state: running")

            case .ended:
                self.statusMessage = "Workout ended"
                self.isWorkoutRunning = false
                self.addDebug("Workout state: ended")

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
                                    self.addDebug("Finish workout error: \(error.localizedDescription)")
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
                self.addDebug("Workout state: paused")

            @unknown default:
                self.addDebug("Workout state: unknown")
            }
        }
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.statusMessage = "Workout failed"
            self.isWorkoutRunning = false
            self.addDebug("Workout failed: \(error.localizedDescription)")
        }

        print("Workout failed: \(error.localizedDescription)")
    }

    private func addDebug(_ message: String) {
        let timestamp = Self.shortTimeString()
        let line = "\(timestamp) \(message)"

        debugMessages.insert(line, at: 0)

        if debugMessages.count > 8 {
            debugMessages.removeLast()
        }
    }

    private static func shortTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}

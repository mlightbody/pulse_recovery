import SwiftUI

struct ContentView: View {
    @StateObject private var manager = LiveHeartRateManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Pulse Recovery")
                    .font(.headline)

                Text(manager.heartRateText)
                    .font(.title2)
                    .bold()

                Text(manager.statusMessage)
                    .font(.caption)
                    .multilineTextAlignment(.center)

                if manager.mode == .recoveryRecording {
                    Text("Recovery: \(manager.recoveryElapsedSeconds)s / 120s")
                        .font(.caption2)
                }

                if manager.hasRecoveryResult {
                    VStack(spacing: 4) {
                        Text("End HR: \(manager.endHrText)")
                        Text("60s HR: \(manager.hr60Text)")
                        Text("120s HR: \(manager.hr120Text)")
                        Text("Samples: \(manager.sampleCount)")
                    }
                    .font(.caption2)
                } else {
                    Text("Samples: \(manager.sampleCount)")
                        .font(.caption2)
                }

                Button {
                    manager.primaryButtonPressed()
                } label: {
                    Text(manager.buttonTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.isButtonDisabled)

                VStack(alignment: .leading, spacing: 3) {
                    ForEach(manager.debugMessages, id: \.self) { message in
                        Text(message)
                            .font(.system(size: 9))
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }
}

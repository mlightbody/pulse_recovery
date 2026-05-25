import SwiftUI

struct ContentView: View {
    @StateObject private var heartRateManager = LiveHeartRateManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Pulse Recovery")
                    .font(.headline)

                Text(heartRateManager.heartRateText)
                    .font(.title2)
                    .bold()

                Text(heartRateManager.statusMessage)
                    .font(.caption)
                    .multilineTextAlignment(.center)

                Text("Samples: \(heartRateManager.sampleCount)")
                    .font(.caption2)

                Text("Button taps: \(heartRateManager.buttonTapCount)")
                    .font(.caption2)

                Button {
                    heartRateManager.buttonPressed()
                } label: {
                    Text(heartRateManager.buttonTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                VStack(alignment: .leading, spacing: 3) {
                    ForEach(heartRateManager.debugMessages, id: \.self) { message in
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

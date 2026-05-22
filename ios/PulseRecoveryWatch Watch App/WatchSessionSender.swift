import Foundation
import WatchConnectivity

final class WatchSessionSender: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionSender()

    @Published var statusMessage = "Ready"

    private override init() {
        super.init()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        } else {
            statusMessage = "WCSession not supported"
        }
    }

    func sendFakeRecoverySession() {
        let session = WCSession.default

        guard session.activationState == .activated else {
            statusMessage = "Session not activated"
            return
        }

        let message: [String: Any] = [
            "type": "fakeRecoverySession",
            "peakHr": 170,
            "hr60": 100,
            "hr120": 80,
            "timestamp": Date().timeIntervalSince1970
        ]

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                DispatchQueue.main.async {
                    self.statusMessage = "Send failed"
                }
                print(error.localizedDescription)
            }

            DispatchQueue.main.async {
                self.statusMessage = "Sent"
            }
        } else {
            session.transferUserInfo(message)

            DispatchQueue.main.async {
                self.statusMessage = "Queued"
            }
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            if let error = error {
                self.statusMessage = "Activation failed"
                print(error.localizedDescription)
            } else {
                self.statusMessage = "Ready"
            }
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}

//
//  WatchSessionReceiver.swift
//  Runner
//
//  Created by Malcolm Lightbody on 28/05/2026.
//

import Foundation
import Flutter
import WatchConnectivity

final class WatchSessionReceiver: NSObject, WCSessionDelegate {
    static let shared = WatchSessionReceiver()

    private var methodChannel: FlutterMethodChannel?
    private let latestSessionKey = "latest_watch_recovery_session"

    private override init() {
        super.init()
        activateWatchSessionIfSupported()
    }

    func configure(messenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(
            name: "pulse_recovery/watch_session",
            binaryMessenger: messenger
        )

        methodChannel?.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                result(
                    FlutterError(
                        code: "receiver_unavailable",
                        message: "WatchSessionReceiver unavailable",
                        details: nil
                    )
                )
                return
            }

            switch call.method {
            case "getLatestWatchSession":
                result(self.loadLatestSession())

            case "clearLatestWatchSession":
                self.clearLatestSession()
                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        print("WatchSessionReceiver configured")
    }

    private func activateWatchSessionIfSupported() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity not supported on this device")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()

        print("iPhone WCSession activating")
    }

    private func handleIncomingSession(_ payload: [String: Any], source: String) {
        print("WATCH SESSION RECEIVED via \(source):")
        print(payload)

        saveLatestSession(payload)

        DispatchQueue.main.async {
            self.methodChannel?.invokeMethod(
                "watchSessionReceived",
                arguments: payload
            )
        }
    }

    private func saveLatestSession(_ payload: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(payload) else {
            print("Watch session payload is not valid JSON")
            return
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [])
            UserDefaults.standard.set(data, forKey: latestSessionKey)
            UserDefaults.standard.synchronize()
            print("Saved latest watch session")
        } catch {
            print("Failed to save watch session: \(error.localizedDescription)")
        }
    }

    private func loadLatestSession() -> [String: Any]? {
        guard let data = UserDefaults.standard.data(forKey: latestSessionKey) else {
            return nil
        }

        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [])

            if let dictionary = object as? [String: Any] {
                return dictionary
            }

            return nil
        } catch {
            print("Failed to load watch session: \(error.localizedDescription)")
            return nil
        }
    }

    private func clearLatestSession() {
        UserDefaults.standard.removeObject(forKey: latestSessionKey)
        UserDefaults.standard.synchronize()

        DispatchQueue.main.async {
            self.methodChannel?.invokeMethod(
                "watchSessionCleared",
                arguments: nil
            )
        }

        print("Cleared latest watch session")
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("iPhone WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("iPhone WCSession activated: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("iPhone WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("iPhone WCSession deactivated")
        WCSession.default.activate()
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        handleIncomingSession(message, source: "didReceiveMessage")
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        handleIncomingSession(message, source: "didReceiveMessageWithReply")

        replyHandler([
            "status": "received",
            "receivedAt": Date().timeIntervalSince1970
        ])
    }

    func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        handleIncomingSession(userInfo, source: "didReceiveUserInfo")
    }
}

import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        print("AppDelegate didFinishLaunching")

        if let registrar = self.registrar(forPlugin: "WatchSessionReceiver") {
            print("Flutter plugin registrar found")
            WatchSessionReceiver.shared.configure(
                messenger: registrar.messenger()
            )
        } else {
            print("Flutter plugin registrar NOT found")
        }

        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }
}

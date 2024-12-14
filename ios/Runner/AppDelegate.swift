import Flutter
import UIKit
import OneSignalFramework

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // // Remove this method to stop OneSignal Debugging
    // OneSignal.Debug.setLogLevel(.LL_VERBOSE)
    
    // // OneSignal initialization
    // OneSignal.initialize("0717fd2b-d830-4863-8b7a-bea31b02b92a")
    
    // // Request notification permission
    // OneSignal.Notifications.requestPermission({ accepted in
    //   print("User accepted notifications: \(accepted)")
    // }, fallbackToSettings: true)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

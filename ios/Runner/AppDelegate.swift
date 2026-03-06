import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let didLaunch = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      
      // Register MusicKit plugin
      if let registrar = self.registrar(forPlugin: "MusicKitPlugin") {
        MusicKitPlugin.register(with: registrar)
      } else {
        NSLog("[MusicKitPlugin] Failed to acquire registrar during launch; continuing without plugin registration.")
      }
      
      // Register AlphabetIndexView platform view
      if let registrar = self.registrar(forPlugin: "AlphabetIndexView") {
        let factory = AlphabetIndexViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "com.fastestmusic/alphabet_index_view")
      } else {
        NSLog("[AlphabetIndexView] Failed to acquire registrar during launch; continuing without platform view registration.")
      }
    }

    return didLaunch
  }
}

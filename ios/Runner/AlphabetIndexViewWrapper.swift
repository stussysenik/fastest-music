import SwiftUI
import Flutter

/// A Flutter platform view that wraps the AlphabetIndexView SwiftUI component
class AlphabetIndexViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return AlphabetIndexPlatformView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class AlphabetIndexPlatformView: NSObject, FlutterPlatformView {
    private var viewContainer: UIView
    private let methodChannel: FlutterMethodChannel
    private var hostingController: UIHostingController<AlphabetIndexView>?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        viewContainer = UIView(frame: frame)
        methodChannel = FlutterMethodChannel(
            name: "com.fastestmusic/alphabet_index_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        let letters = (args as? [String: Any])?["letters"] as? [String]
        configureAlphabetView(with: letters)
        setupMethodChannel()
    }

    func view() -> UIView {
        return viewContainer
    }

    private func configureAlphabetView(with letters: [String]?) {
        hostingController?.view.removeFromSuperview()

        let alphabetView = AlphabetIndexView(
            letters: letters ?? AlphabetIndexView.defaultLetters
        ) { [weak self] letter in
            self?.methodChannel.invokeMethod("onLetterChanged", arguments: ["letter": letter])
        } onLetterSelected: { [weak self] letter in
            self?.methodChannel.invokeMethod("onLetterSelected", arguments: ["letter": letter])
        }

        let controller = UIHostingController(rootView: alphabetView)
        controller.view.backgroundColor = .clear
        controller.view.frame = viewContainer.bounds
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        viewContainer.addSubview(controller.view)
        hostingController = controller
    }

    private func setupMethodChannel() {
        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "View disposed", details: nil))
                return
            }

            if call.method == "updateLetters",
               let letters = (call.arguments as? [String: Any])?["letters"] as? [String] {
                self.configureAlphabetView(with: letters)
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }
}

import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: CardWindowController?
    private var viewModel: CardViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let model = CardViewModel()
        self.viewModel = model
        let controller = CardWindowController(viewModel: model)
        self.windowController = controller
        controller.showWindow(nil)
        controller.window?.orderFrontRegardless()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

@main
struct AbigailFlowerCardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
                .frame(width: 0, height: 0)
        }
    }
}

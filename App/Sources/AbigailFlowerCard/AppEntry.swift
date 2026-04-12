import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var workspaceController: WorkspaceController?
    var windowRegistry: WindowRegistry?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let workspaceController = WorkspaceController()
        let windowRegistry = WindowRegistry(workspaceController: workspaceController)

        self.workspaceController = workspaceController
        self.windowRegistry = windowRegistry

        windowRegistry.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            windowRegistry?.revealAllCards()
        }
        return true
    }
}

@main
struct AbigailFlowerCardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            if let workspaceController = appDelegate.workspaceController,
               let windowRegistry = appDelegate.windowRegistry {
                PreferencesView(
                    workspaceController: workspaceController,
                    windowRegistry: windowRegistry
                )
            } else {
                ProgressView()
                    .frame(width: 360, height: 220)
            }
        }
    }
}

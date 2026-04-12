import Foundation
import Darwin

enum LaunchAgentController {
    static let label = "com.abigailflower.card"

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        enabled ? install() : uninstall()
    }

    private static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    @discardableResult
    private static func install() -> Bool {
        let fm = FileManager.default
        let appURL = Bundle.main.bundleURL

        do {
            try fm.createDirectory(at: plistURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try launchAgentContents(for: appURL).write(to: plistURL, atomically: true, encoding: .utf8)
        } catch {
            return false
        }

        _ = runLaunchctl(arguments: ["bootout", "gui/\(getuid())", plistURL.path], ignoreFailure: true)
        return runLaunchctl(arguments: ["bootstrap", "gui/\(getuid())", plistURL.path], ignoreFailure: false)
    }

    @discardableResult
    private static func uninstall() -> Bool {
        let fm = FileManager.default
        _ = runLaunchctl(arguments: ["bootout", "gui/\(getuid())", plistURL.path], ignoreFailure: true)
        do {
            if fm.fileExists(atPath: plistURL.path) {
                try fm.removeItem(at: plistURL)
            }
            return true
        } catch {
            return false
        }
    }

    private static func launchAgentContents(for appURL: URL) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>\(label)</string>
          <key>ProgramArguments</key>
          <array>
            <string>/usr/bin/open</string>
            <string>-gj</string>
            <string>\(xmlEscaped(appURL.path))</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
        </dict>
        </plist>
        """
    }

    @discardableResult
    private static func runLaunchctl(arguments: [String], ignoreFailure: Bool) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()
            return ignoreFailure || process.terminationStatus == 0
        } catch {
            return ignoreFailure
        }
    }

    private static func xmlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

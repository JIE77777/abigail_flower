import SwiftUI
import AppKit

struct PreferencesView: View {
    @ObservedObject var workspaceController: WorkspaceController
    let windowRegistry: WindowRegistry

    @State private var launchAtLoginEnabled = LaunchAgentController.isEnabled
    @State private var statusMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("偏好设置")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.primary.opacity(0.92))

                Text("这里只放少数会长期影响体验的项目，不把卡片本体变成工具箱。")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }

            PreferenceSection(title: "显示") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("卡片透明度")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Spacer(minLength: 12)
                        Text("\(Int(workspaceController.config.cardOpacity * 100))%")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.secondary)
                            .monospacedDigit()
                    }

                    Slider(
                        value: Binding(
                            get: { workspaceController.config.cardOpacity },
                            set: { workspaceController.setCardOpacity($0) }
                        ),
                        in: 0.82...1.0,
                        step: 0.01
                    )
                    .tint(Color(red: 0.63, green: 0.46, blue: 0.42))

                    Text("会立即作用到所有卡片，也会写回本地配置。")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.secondary.opacity(0.88))
                }
            }

            PreferenceSection(title: "启动") {
                Toggle(isOn: Binding(
                    get: { launchAtLoginEnabled },
                    set: { updateLaunchAtLogin($0) }
                )) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("开机时自动打开阿比盖尔之花")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Text("使用当前安装路径写入自动启动项。")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.secondary.opacity(0.88))
                    }
                }
                .toggleStyle(.switch)
            }

            PreferenceSection(title: "整理") {
                HStack(spacing: 10) {
                    Button("找回全部卡片") {
                        windowRegistry.revealAllCards()
                        statusMessage = "已把所有卡片带回视野。"
                    }
                    .buttonStyle(PreferenceButtonStyle(prominent: false))

                    Button("重置位置") {
                        windowRegistry.resetAllCardPositions()
                        statusMessage = "已重置所有卡片位置。"
                    }
                    .buttonStyle(PreferenceButtonStyle(prominent: false))
                }
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(width: 420, height: 308, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            launchAtLoginEnabled = LaunchAgentController.isEnabled
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        let succeeded = LaunchAgentController.setEnabled(enabled)
        launchAtLoginEnabled = LaunchAgentController.isEnabled
        if succeeded {
            statusMessage = enabled ? "已开启开机启动。" : "已关闭开机启动。"
        } else {
            statusMessage = "未能更新开机启动，请稍后再试。"
        }
    }
}

private struct PreferenceSection<Content: View>: View {
    let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color.secondary.opacity(0.88))

            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.74))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }
}

private struct PreferenceButtonStyle: ButtonStyle {
    let prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(prominent ? Color.white : Color.primary.opacity(0.88))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        prominent
                            ? Color(red: 0.56, green: 0.39, blue: 0.36)
                            : Color.white.opacity(configuration.isPressed ? 0.88 : 0.68)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(prominent ? 0.0 : 0.06), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

enum PreferencesWindowAction {
    static func show() {
        if NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
            return
        }
        _ = NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}

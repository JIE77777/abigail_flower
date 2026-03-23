import SwiftUI
import AppKit

struct CardView: View {
    @ObservedObject var viewModel: CardViewModel
    @State private var isFlowerHovered = false

    private let quotePanelHeight: CGFloat = 122

    private var theme: CardTheme {
        CardTheme.resolve(daysRemaining: viewModel.content.daysRemaining)
    }

    private var targetBadgeText: String {
        String(format: "%02d · %02d", viewModel.config.targetMonth, viewModel.config.targetDay)
    }

    private var primaryEntries: [CardEntry] {
        viewModel.content.entries.filter { !isEasterEgg($0) }
    }

    private var easterEggLine: String? {
        viewModel.content.entries.first(where: isEasterEgg)?.lines.first
    }

    private var hasBilingualQuote: Bool {
        primaryEntries.contains { $0.lines.count > 1 }
    }

    var body: some View {
        ZStack {
            backgroundLayer
            decorativeFlower

            VStack(alignment: .leading, spacing: 16) {
                header
                countdownBlock
                Spacer(minLength: 0)
                quoteBlock
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
        }
        .opacity(viewModel.config.cardOpacity)
        .frame(width: viewModel.panelSize.width, height: viewModel.panelSize.height)
        .background(Color.clear)
        .contextMenu {
            Button("换一句") {
                viewModel.reroll()
            }
            Button("刷新今天") {
                viewModel.reload(forceConfig: true)
            }
            Divider()
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.content.title)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(Color(red: 0.34, green: 0.20, blue: 0.19))

                Text(targetBadgeText)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.badgeText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(theme.badgeFill)
                    )
            }

            Spacer(minLength: 0)

            Button(action: viewModel.reroll) {
                ZStack {
                    Circle()
                        .fill(theme.buttonFill.opacity(isFlowerHovered ? 1.0 : 0.86))
                        .frame(width: 50, height: 50)
                    Circle()
                        .stroke(theme.buttonStroke, lineWidth: 1)
                        .frame(width: 50, height: 50)
                    flowerImage
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 27, height: 27)
                }
                .shadow(color: theme.buttonShadow, radius: 12, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .help("今天再换一句")
            .onHover { hovering in
                isFlowerHovered = hovering
            }
        }
    }

    private var countdownBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            if viewModel.content.daysRemaining == 0 {
                Text("今天")
                    .font(.system(size: 78, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.18, green: 0.10, blue: 0.10))
                    .tracking(-1.6)

                Text("就是 8.31")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.unitColor)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(viewModel.content.daysRemaining)")
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.18, green: 0.10, blue: 0.10))
                        .tracking(-2.8)

                    Text("天")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.unitColor)
                }
            }
        }
    }

    private var quoteBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("今日摘句")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.6)
                    .foregroundColor(theme.sectionLabelText)

                if hasBilingualQuote {
                    Text("WENDY 摘录")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundColor(theme.quoteAccent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(theme.quoteTagFill)
                        )
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(primaryEntries) { entry in
                    EntryView(entry: entry, accentColor: theme.quoteAccent)
                }
            }

            Spacer(minLength: 0)

            if let eggLine = easterEggLine {
                EggChip(text: eggLine, accentColor: theme.quoteAccent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: quotePanelHeight, maxHeight: quotePanelHeight, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.quotePanelFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(theme.quotePanelStroke, lineWidth: 1)
                )
        )
        .clipped()
    }

    private var backgroundLayer: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [theme.paperTop, theme.paperMid, theme.paperBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(theme.cardStroke, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.34), Color.white.opacity(0.04)],
                            center: .topLeading,
                            startRadius: 20,
                            endRadius: 240
                        )
                    )
            )
            .shadow(color: theme.cardShadow, radius: 26, x: 0, y: 18)
    }

    private var decorativeFlower: some View {
        flowerImage
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: 124, height: 124)
            .opacity(theme.watermarkOpacity)
            .offset(x: 118, y: 98)
    }

    private var flowerImage: Image {
        if let url = AbigailPaths.bundledFlowerIcon(), let nsImage = NSImage(contentsOf: url) {
            return Image(nsImage: nsImage)
        }
        return Image(systemName: "sparkles")
    }

    private func isEasterEgg(_ entry: CardEntry) -> Bool {
        entry.lines.first?.hasPrefix("隐藏彩蛋：") == true
    }
}

private struct EntryView: View {
    let entry: CardEntry
    let accentColor: Color

    var body: some View {
        if entry.lines.count > 1 {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 999)
                    .fill(accentColor.opacity(0.72))
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 5) {
                    if let first = entry.lines.first {
                        Text(first)
                            .font(.system(size: 15, weight: .semibold, design: .serif))
                            .italic()
                            .foregroundColor(Color(red: 0.28, green: 0.17, blue: 0.16))
                            .lineSpacing(2)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if entry.lines.count > 1 {
                        Text(entry.lines[1])
                            .font(.system(size: 13, weight: .medium, design: .default))
                            .foregroundColor(Color(red: 0.44, green: 0.28, blue: 0.27))
                            .lineSpacing(2)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        } else {
            if let first = entry.lines.first {
                Text(first)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.28, green: 0.17, blue: 0.16))
                    .lineSpacing(2)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct EggChip: View {
    let text: String
    let accentColor: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(Color(red: 0.55, green: 0.39, blue: 0.36))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(accentColor.opacity(0.12))
            )
    }
}

private struct CardTheme {
    let paperTop: Color
    let paperMid: Color
    let paperBottom: Color
    let badgeFill: Color
    let badgeText: Color
    let buttonFill: Color
    let buttonStroke: Color
    let buttonShadow: Color
    let unitColor: Color
    let quoteAccent: Color
    let quoteTagFill: Color
    let sectionLabelText: Color
    let quotePanelFill: Color
    let quotePanelStroke: Color
    let cardStroke: Color
    let cardShadow: Color
    let watermarkOpacity: Double

    private static let milestoneDays: Set<Int> = [200, 160, 150, 120, 100, 60, 50, 30, 10, 7, 3, 1]

    static func resolve(daysRemaining: Int) -> CardTheme {
        if daysRemaining == 0 {
            return CardTheme(
                paperTop: Color(red: 0.99, green: 0.96, blue: 0.89),
                paperMid: Color(red: 0.97, green: 0.92, blue: 0.84),
                paperBottom: Color(red: 0.94, green: 0.88, blue: 0.79),
                badgeFill: Color(red: 0.88, green: 0.77, blue: 0.60).opacity(0.28),
                badgeText: Color(red: 0.50, green: 0.35, blue: 0.22),
                buttonFill: Color.white.opacity(0.54),
                buttonStroke: Color(red: 0.79, green: 0.66, blue: 0.47).opacity(0.42),
                buttonShadow: Color(red: 0.57, green: 0.40, blue: 0.24).opacity(0.15),
                unitColor: Color(red: 0.58, green: 0.39, blue: 0.24),
                quoteAccent: Color(red: 0.79, green: 0.60, blue: 0.34),
                quoteTagFill: Color(red: 0.89, green: 0.80, blue: 0.61).opacity(0.24),
                sectionLabelText: Color(red: 0.58, green: 0.41, blue: 0.27),
                quotePanelFill: Color.white.opacity(0.55),
                quotePanelStroke: Color.white.opacity(0.52),
                cardStroke: Color.white.opacity(0.44),
                cardShadow: Color(red: 0.45, green: 0.30, blue: 0.18).opacity(0.17),
                watermarkOpacity: 0.06
            )
        }

        if daysRemaining <= 10 {
            return CardTheme(
                paperTop: Color(red: 0.98, green: 0.94, blue: 0.91),
                paperMid: Color(red: 0.95, green: 0.88, blue: 0.87),
                paperBottom: Color(red: 0.92, green: 0.82, blue: 0.83),
                badgeFill: Color(red: 0.84, green: 0.56, blue: 0.58).opacity(0.20),
                badgeText: Color(red: 0.57, green: 0.31, blue: 0.34),
                buttonFill: Color.white.opacity(0.52),
                buttonStroke: Color(red: 0.78, green: 0.48, blue: 0.50).opacity(0.38),
                buttonShadow: Color(red: 0.55, green: 0.30, blue: 0.33).opacity(0.14),
                unitColor: Color(red: 0.57, green: 0.33, blue: 0.35),
                quoteAccent: Color(red: 0.77, green: 0.46, blue: 0.49),
                quoteTagFill: Color(red: 0.86, green: 0.64, blue: 0.66).opacity(0.22),
                sectionLabelText: Color(red: 0.58, green: 0.34, blue: 0.35),
                quotePanelFill: Color.white.opacity(0.53),
                quotePanelStroke: Color.white.opacity(0.51),
                cardStroke: Color.white.opacity(0.43),
                cardShadow: Color(red: 0.44, green: 0.24, blue: 0.27).opacity(0.16),
                watermarkOpacity: 0.06
            )
        }

        if milestoneDays.contains(daysRemaining) {
            return CardTheme(
                paperTop: Color(red: 0.99, green: 0.95, blue: 0.88),
                paperMid: Color(red: 0.96, green: 0.90, blue: 0.83),
                paperBottom: Color(red: 0.93, green: 0.85, blue: 0.78),
                badgeFill: Color(red: 0.88, green: 0.73, blue: 0.50).opacity(0.24),
                badgeText: Color(red: 0.55, green: 0.37, blue: 0.22),
                buttonFill: Color.white.opacity(0.50),
                buttonStroke: Color(red: 0.79, green: 0.61, blue: 0.38).opacity(0.38),
                buttonShadow: Color(red: 0.55, green: 0.37, blue: 0.20).opacity(0.14),
                unitColor: Color(red: 0.58, green: 0.38, blue: 0.26),
                quoteAccent: Color(red: 0.79, green: 0.57, blue: 0.33),
                quoteTagFill: Color(red: 0.89, green: 0.77, blue: 0.55).opacity(0.22),
                sectionLabelText: Color(red: 0.57, green: 0.40, blue: 0.26),
                quotePanelFill: Color.white.opacity(0.53),
                quotePanelStroke: Color.white.opacity(0.51),
                cardStroke: Color.white.opacity(0.43),
                cardShadow: Color(red: 0.48, green: 0.33, blue: 0.19).opacity(0.16),
                watermarkOpacity: 0.06
            )
        }

        return CardTheme(
            paperTop: Color(red: 0.98, green: 0.95, blue: 0.90),
            paperMid: Color(red: 0.95, green: 0.90, blue: 0.86),
            paperBottom: Color(red: 0.91, green: 0.85, blue: 0.83),
            badgeFill: Color(red: 0.85, green: 0.73, blue: 0.68).opacity(0.20),
            badgeText: Color(red: 0.51, green: 0.35, blue: 0.33),
            buttonFill: Color.white.opacity(0.46),
            buttonStroke: Color(red: 0.71, green: 0.56, blue: 0.52).opacity(0.40),
            buttonShadow: Color(red: 0.45, green: 0.27, blue: 0.23).opacity(0.12),
            unitColor: Color(red: 0.49, green: 0.31, blue: 0.29),
            quoteAccent: Color(red: 0.68, green: 0.52, blue: 0.49),
            quoteTagFill: Color(red: 0.84, green: 0.72, blue: 0.69).opacity(0.18),
            sectionLabelText: Color(red: 0.53, green: 0.38, blue: 0.36),
            quotePanelFill: Color.white.opacity(0.52),
            quotePanelStroke: Color.white.opacity(0.52),
            cardStroke: Color.white.opacity(0.44),
            cardShadow: Color(red: 0.36, green: 0.22, blue: 0.20).opacity(0.16),
            watermarkOpacity: 0.05
        )
    }
}

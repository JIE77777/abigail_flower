import SwiftUI
import AppKit

struct CardView: View {
    @ObservedObject var viewModel: CardViewModel
    @State private var isFlowerHovered = false

    var body: some View {
        ZStack {
            backgroundLayer
            decorativeFlower

            VStack(alignment: .leading, spacing: 20) {
                header
                countdownBlock
                quoteBlock
                Spacer(minLength: 0)
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

                Text("点花朵，今天再换一句")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.54, green: 0.38, blue: 0.35).opacity(0.88))
            }

            Spacer(minLength: 0)

            Button(action: viewModel.reroll) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(isFlowerHovered ? 0.76 : 0.52))
                        .frame(width: 56, height: 56)
                    Circle()
                        .stroke(Color(red: 0.71, green: 0.56, blue: 0.52).opacity(0.52), lineWidth: 1)
                        .frame(width: 56, height: 56)
                    flowerImage
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                }
                .shadow(color: Color(red: 0.45, green: 0.27, blue: 0.23).opacity(0.14), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .help("点一下，今天再换一句")
            .onHover { hovering in
                isFlowerHovered = hovering
            }
        }
    }

    private var countdownBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.content.daysRemaining == 0 {
                Text("今天")
                    .font(.system(size: 78, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.18, green: 0.10, blue: 0.10))
                    .tracking(-1.6)

                Text("就是 8.31")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.48, green: 0.30, blue: 0.28))
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(viewModel.content.daysRemaining)")
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.18, green: 0.10, blue: 0.10))
                        .tracking(-2.8)

                    Text("天")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.49, green: 0.31, blue: 0.29))
                }

                Text("一步一步靠近 8 月 31 日")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.54, green: 0.38, blue: 0.35).opacity(0.9))
            }
        }
    }

    private var quoteBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.content.entries) { entry in
                EntryView(entry: entry)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.56))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                )
        )
    }

    private var backgroundLayer: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.95, blue: 0.90),
                        Color(red: 0.95, green: 0.90, blue: 0.86),
                        Color(red: 0.91, green: 0.85, blue: 0.83),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.44), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.38),
                                Color.white.opacity(0.04),
                            ],
                            center: .topLeading,
                            startRadius: 20,
                            endRadius: 240
                        )
                    )
            )
            .shadow(color: Color(red: 0.36, green: 0.22, blue: 0.20).opacity(0.16), radius: 26, x: 0, y: 18)
    }

    private var decorativeFlower: some View {
        flowerImage
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: 124, height: 124)
            .opacity(0.06)
            .offset(x: 118, y: 98)
    }

    private var flowerImage: Image {
        if let url = AbigailPaths.bundledFlowerIcon(), let nsImage = NSImage(contentsOf: url) {
            return Image(nsImage: nsImage)
        }
        return Image(systemName: "sparkles")
    }
}

private struct EntryView: View {
    let entry: CardEntry

    var body: some View {
        VStack(alignment: .leading, spacing: entry.lines.count > 1 ? 5 : 0) {
            if let first = entry.lines.first {
                Text(first)
                    .font(.system(size: entry.lines.count > 1 ? 15 : 16, weight: .semibold, design: entry.lines.count > 1 ? .serif : .rounded))
                    .foregroundColor(Color(red: 0.28, green: 0.17, blue: 0.16))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(Array(entry.lines.dropFirst()), id: \.self) { line in
                Text(line)
                    .font(.system(size: 15, weight: .medium, design: .default))
                    .foregroundColor(Color(red: 0.40, green: 0.24, blue: 0.23))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

import SwiftUI
import AppKit

final class AbigailPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class CardWindowController: NSWindowController {
    init(viewModel: CardViewModel) {
        let size = viewModel.panelSize
        let panel = AbigailPanel(
            contentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.level = .normal
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isExcludedFromWindowsMenu = true
        panel.title = "阿比盖尔之花"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.setFrameAutosaveName("AbigailFlowerPanel")

        let hosting = NSHostingView(rootView: CardView(viewModel: viewModel))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView?.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: panel.contentView!.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: panel.contentView!.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: panel.contentView!.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: panel.contentView!.bottomAnchor),
        ])

        super.init(window: panel)
        if !panel.setFrameUsingName("AbigailFlowerPanel") {
            position(panel: panel, using: viewModel)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func position(panel: NSPanel, using viewModel: CardViewModel) {
        if let screen = NSScreen.main {
            let position = viewModel.panelPosition
            let y = screen.visibleFrame.maxY - position.y - viewModel.panelSize.height
            panel.setFrameOrigin(NSPoint(x: position.x, y: y))
        }
    }
}

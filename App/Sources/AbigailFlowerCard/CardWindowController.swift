import SwiftUI
import AppKit

final class AbigailPanel: NSPanel {
    var onPrimaryMouseDown: (() -> Void)?
    var onPrimaryMouseUp: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            onPrimaryMouseDown?()
        case .leftMouseUp:
            onPrimaryMouseUp?()
        default:
            break
        }
        super.sendEvent(event)
    }
}

@MainActor
final class CardWindowController: NSWindowController, NSWindowDelegate {
    let cardID: UUID

    var onFrameDidChange: ((CGRect) -> Void)?
    var onPotentialDragStart: (() -> Void)?
    var onPotentialDragEnd: (() -> Void)?
    var onWindowFocused: (() -> Void)?

    init(cardID: UUID, viewModel: CardViewModel, initialFrame: CGRect) {
        self.cardID = cardID

        let panel = AbigailPanel(
            contentRect: initialFrame,
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
        panel.delegate = self

        panel.onPrimaryMouseDown = { [weak self, weak panel] in
            panel?.makeKeyAndOrderFront(nil)
            self?.onWindowFocused?()
            self?.onPotentialDragStart?()
        }
        panel.onPrimaryMouseUp = { [weak self] in
            self?.onPotentialDragEnd?()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func currentFrame() -> CGRect? {
        window?.frame
    }

    func applyFrame(_ frame: CGRect, animate: Bool = false) {
        window?.setFrame(frame, display: true, animate: animate)
    }

    func windowDidMove(_ notification: Notification) {
        guard let frame = window?.frame else { return }
        onFrameDidChange?(frame)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        onWindowFocused?()
    }
}

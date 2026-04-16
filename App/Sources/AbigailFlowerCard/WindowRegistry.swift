import Foundation
import AppKit
import Combine

@MainActor
final class WindowRegistry: ObservableObject {
    @Published private(set) var mergeTargetCardID: UUID?

    private let workspaceController: WorkspaceController
    private var windowControllers: [UUID: CardWindowController] = [:]
    private var cancellables = Set<AnyCancellable>()

    private var armedDragCardID: UUID?
    private var draggingCardID: UUID?
    private var pendingMergeTargetID: UUID?

    init(workspaceController: WorkspaceController) {
        self.workspaceController = workspaceController

        workspaceController.$workspace
            .sink { [weak self] _ in
                self?.syncWindows()
            }
            .store(in: &cancellables)
    }

    func start() {
        syncWindows()
    }

    func focusCard(id: UUID) {
        guard let controller = windowControllers[id] else { return }
        workspaceController.focusCard(id: id)
        NSApp.activate(ignoringOtherApps: true)
        controller.showWindow(nil)
        controller.window?.orderFrontRegardless()
        controller.window?.makeKey()
    }

    func createStandaloneCard(relativeTo cardID: UUID?, near origin: CGPoint? = nil) -> UUID {
        let frame = origin.map(defaultFrame(nearScreenPoint:))
        let cardID = workspaceController.createStandaloneCard(relativeTo: cardID, frame: frame.map(SavedCardFrame.init(rect:)))
        syncWindows()
        focusCard(id: cardID)
        return cardID
    }

    @discardableResult
    func detachPage(pageID: UUID, from sourceCardID: UUID, dropPoint: CGPoint? = nil) -> UUID? {
        let frame = dropPoint.map(defaultFrame(nearScreenPoint:))
        let detachedID = workspaceController.detachPage(pageID: pageID, from: sourceCardID, frame: frame.map(SavedCardFrame.init(rect:)))
        syncWindows()
        if let detachedID {
            focusCard(id: detachedID)
        }
        return detachedID
    }

    func revealAllCards() {
        let cards = workspaceController.cards
        for (index, card) in cards.enumerated() {
            guard let controller = windowControllers[card.id] else { continue }
            let adjustedFrame = visibleFrame(for: card.frame?.rect ?? defaultFrame(for: index))
            controller.applyFrame(adjustedFrame)
            workspaceController.updateCardFrame(cardID: card.id, frame: SavedCardFrame(rect: adjustedFrame))
            controller.showWindow(nil)
            controller.window?.orderFrontRegardless()
        }
    }

    func resetAllCardPositions() {
        let cards = workspaceController.cards
        for (index, card) in cards.enumerated() {
            guard let controller = windowControllers[card.id] else { continue }
            let frame = defaultFrame(for: index)
            controller.applyFrame(frame)
            workspaceController.updateCardFrame(cardID: card.id, frame: SavedCardFrame(rect: frame))
            controller.showWindow(nil)
            controller.window?.orderFrontRegardless()
        }
    }

    private func syncWindows() {
        let currentCardIDs = Set(workspaceController.cards.map(\.id))
        let existingCardIDs = Set(windowControllers.keys)

        for removedID in existingCardIDs.subtracting(currentCardIDs) {
            windowControllers[removedID]?.close()
            windowControllers[removedID] = nil
        }

        for (index, card) in workspaceController.cards.enumerated() {
            let isActivelyDragging = armedDragCardID == card.id || draggingCardID == card.id

            if let controller = windowControllers[card.id] {
                guard !isActivelyDragging else { continue }

                if let frame = card.frame?.rect, controller.currentFrame() != frame {
                    controller.applyFrame(frame)
                } else if controller.currentFrame() == nil {
                    controller.applyFrame(defaultFrame(for: index))
                }
                continue
            }

            let initialFrame = visibleFrame(for: card.frame?.rect ?? defaultFrame(for: index))
            let controller = makeWindowController(for: card.id, initialFrame: initialFrame)
            windowControllers[card.id] = controller
            controller.showWindow(nil)
            controller.window?.orderFrontRegardless()
        }
    }

    private func makeWindowController(for cardID: UUID, initialFrame: CGRect) -> CardWindowController {
        let viewModel = CardViewModel(cardID: cardID, workspaceController: workspaceController, windowRegistry: self)
        let controller = CardWindowController(cardID: cardID, viewModel: viewModel, initialFrame: initialFrame)
        controller.onFrameDidChange = { [weak self] rect in
            self?.handleFrameChange(for: cardID, rect: rect)
        }
        controller.onPotentialDragStart = { [weak self] in
            self?.beginPotentialWindowDrag(cardID: cardID)
        }
        controller.onPotentialDragEnd = { [weak self] in
            self?.endPotentialWindowDrag(cardID: cardID)
        }
        controller.onWindowFocused = { [weak self] in
            self?.workspaceController.focusCard(id: cardID)
        }
        return controller
    }

    private func handleFrameChange(for cardID: UUID, rect: CGRect) {
        workspaceController.updateCardFrame(cardID: cardID, frame: SavedCardFrame(rect: rect))

        guard armedDragCardID == cardID || draggingCardID == cardID else { return }
        draggingCardID = cardID
        armedDragCardID = nil

        let candidate = mergeTarget(for: cardID, frame: rect)
        pendingMergeTargetID = candidate
        mergeTargetCardID = candidate
    }

    private func beginPotentialWindowDrag(cardID: UUID) {
        armedDragCardID = cardID
        draggingCardID = nil
        pendingMergeTargetID = nil
        mergeTargetCardID = nil
        workspaceController.focusCard(id: cardID)
    }

    private func endPotentialWindowDrag(cardID: UUID) {
        defer {
            armedDragCardID = nil
            draggingCardID = nil
            pendingMergeTargetID = nil
            mergeTargetCardID = nil
        }

        guard draggingCardID == cardID, let targetID = pendingMergeTargetID else { return }
        if let mergedID = workspaceController.mergeCard(sourceID: cardID, into: targetID) {
            syncWindows()
            focusCard(id: mergedID)
        }
    }

    private func mergeTarget(for sourceCardID: UUID, frame: CGRect) -> UUID? {
        let sourceCenter = CGPoint(x: frame.midX, y: frame.midY)
        var bestTarget: (id: UUID, score: CGFloat)?

        for (targetID, controller) in windowControllers where targetID != sourceCardID {
            guard let targetFrame = controller.currentFrame() else { continue }
            let expanded = targetFrame.insetBy(dx: -36, dy: -36)
            guard expanded.contains(sourceCenter) else { continue }

            let intersection = frame.intersection(targetFrame)
            let score = max(intersection.width, 0) * max(intersection.height, 0)
            if bestTarget == nil || score > bestTarget?.score ?? 0 {
                bestTarget = (targetID, score)
            }
        }

        return bestTarget?.id
    }

    private func defaultFrame(for index: Int) -> CGRect {
        let size = CGSize(width: workspaceController.config.panelWidth, height: workspaceController.config.panelHeight)
        let offsetX = CGFloat((index % 4) * 24)
        let offsetY = CGFloat((index % 4) * 28)

        guard let screen = NSScreen.main else {
            return CGRect(x: workspaceController.config.panelX + Double(offsetX), y: workspaceController.config.panelY - Double(offsetY), width: size.width, height: size.height)
        }

        let x = CGFloat(workspaceController.config.panelX) + offsetX
        let y = screen.visibleFrame.maxY - CGFloat(workspaceController.config.panelY) - size.height - offsetY
        return visibleFrame(for: CGRect(x: x, y: y, width: size.width, height: size.height))
    }

    private func defaultFrame(nearScreenPoint point: CGPoint) -> CGRect {
        let size = CGSize(width: workspaceController.config.panelWidth, height: workspaceController.config.panelHeight)
        let rect = CGRect(
            x: point.x - size.width * 0.28,
            y: point.y - size.height * 0.28,
            width: size.width,
            height: size.height
        )
        return visibleFrame(for: rect)
    }

    private func visibleFrame(for rect: CGRect) -> CGRect {
        guard let screen = NSScreen.main else { return rect }
        let visible = screen.visibleFrame.insetBy(dx: 12, dy: 12)
        let x = min(max(rect.origin.x, visible.minX), visible.maxX - rect.width)
        let y = min(max(rect.origin.y, visible.minY), visible.maxY - rect.height)
        return CGRect(x: x, y: y, width: rect.width, height: rect.height)
    }
}

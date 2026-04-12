import Foundation
import SwiftUI
import AppKit
import Combine

@MainActor
final class CardViewModel: ObservableObject {
    @Published private(set) var config: CardConfig
    @Published private(set) var content: CardContent
    @Published private(set) var pages: [CountdownPage]
    @Published private(set) var selectedPageID: UUID?
    @Published private(set) var overviewCards: [CountdownCardOverview]
    @Published private(set) var isMergeTargetHighlighted = false

    let cardID: UUID

    private let engine = CountdownEngine()
    private let workspaceController: WorkspaceController
    private weak var windowRegistry: WindowRegistry?
    private var refreshTimer: Timer?
    private var lastDayStamp: String
    private var cancellables = Set<AnyCancellable>()

    init(cardID: UUID, workspaceController: WorkspaceController, windowRegistry: WindowRegistry) {
        self.cardID = cardID
        self.workspaceController = workspaceController
        self.windowRegistry = windowRegistry

        let now = Date()
        let loadedConfig = workspaceController.config
        let card = workspaceController.card(for: cardID)
        let selectedPageID = card?.selectedPageID
        let pages = card?.pages ?? []
        let currentPage = workspaceController.currentPage(for: cardID, now: now)

        self.config = loadedConfig
        self.pages = pages
        self.selectedPageID = selectedPageID
        self.content = engine.generateContent(config: loadedConfig, page: currentPage, now: now)
        self.overviewCards = workspaceController.overviewCards(currentCardID: cardID, now: now)
        self.lastDayStamp = AppStateStore.dayStamp(from: now)

        bind()
        scheduleRefreshTimer()
    }

    var panelSize: CGSize {
        CGSize(width: CGFloat(config.panelWidth), height: CGFloat(config.panelHeight))
    }

    var currentPage: CountdownPage {
        if let selectedPageID,
           let page = pages.first(where: { $0.id == selectedPageID }) {
            return page
        }
        if let first = pages.first {
            return first
        }
        return workspaceController.currentPage(for: cardID)
    }

    var canDeleteCurrentPage: Bool {
        pages.count > 1
    }

    var canDetachCurrentPage: Bool {
        pages.count > 1
    }

    func reroll() {
        workspaceController.rerollToday()
    }

    func reload(forceConfig: Bool = true) {
        if forceConfig {
            workspaceController.reloadConfig()
        }
        refreshFromWorkspace(now: Date())
    }

    func selectPage(id: UUID) {
        workspaceController.selectPage(cardID: cardID, pageID: id)
    }

    func selectNextPage() {
        guard !pages.isEmpty else { return }
        let currentIndex = pages.firstIndex(where: { $0.id == selectedPageID }) ?? 0
        let nextIndex = (currentIndex + 1) % pages.count
        selectPage(id: pages[nextIndex].id)
    }

    func selectPreviousPage() {
        guard !pages.isEmpty else { return }
        let currentIndex = pages.firstIndex(where: { $0.id == selectedPageID }) ?? 0
        let previousIndex = (currentIndex - 1 + pages.count) % pages.count
        selectPage(id: pages[previousIndex].id)
    }

    func beginEditingCurrentPage() -> CountdownPageDraft {
        workspaceController.beginEditingCurrentPage(in: cardID)
    }

    func beginCreatingPage() -> CountdownPageDraft {
        workspaceController.beginCreatingPage(in: cardID, now: Date())
    }

    func savePage(from draft: CountdownPageDraft) {
        workspaceController.savePage(in: cardID, from: draft)
    }

    func deleteCurrentPage() {
        workspaceController.deleteCurrentPage(in: cardID)
    }

    func openCurrentPageInNewCard() {
        guard canDetachCurrentPage else { return }
        _ = windowRegistry?.detachPage(pageID: currentPage.id, from: cardID, dropPoint: NSEvent.mouseLocation)
    }

    func detachPage(_ pageID: UUID, dropPoint: CGPoint? = nil) {
        _ = windowRegistry?.detachPage(pageID: pageID, from: cardID, dropPoint: dropPoint ?? NSEvent.mouseLocation)
    }

    func createStandaloneCard() {
        _ = windowRegistry?.createStandaloneCard(relativeTo: cardID, near: NSEvent.mouseLocation)
    }

    func focusCard(_ targetCardID: UUID) {
        windowRegistry?.focusCard(id: targetCardID)
    }

    func revealAllCards() {
        windowRegistry?.revealAllCards()
    }

    func resetAllCardPositions() {
        windowRegistry?.resetAllCardPositions()
    }

    func selectOverviewPage(cardID targetCardID: UUID, pageID: UUID) {
        workspaceController.selectPage(cardID: targetCardID, pageID: pageID)
        windowRegistry?.focusCard(id: targetCardID)
    }

    func detachOverviewPage(cardID targetCardID: UUID, pageID: UUID) {
        _ = windowRegistry?.detachPage(pageID: pageID, from: targetCardID, dropPoint: NSEvent.mouseLocation)
    }

    private func bind() {
        workspaceController.$workspace
            .sink { [weak self] _ in
                self?.refreshFromWorkspace(now: Date())
            }
            .store(in: &cancellables)

        workspaceController.$config
            .sink { [weak self] config in
                guard let self else { return }
                self.config = config
                self.refreshFromWorkspace(now: Date())
            }
            .store(in: &cancellables)

        workspaceController.$contentRevision
            .dropFirst()
            .sink { [weak self] _ in
                self?.refreshFromWorkspace(now: Date())
            }
            .store(in: &cancellables)

        if let windowRegistry {
            windowRegistry.$mergeTargetCardID
                .sink { [weak self] mergeTargetID in
                    self?.isMergeTargetHighlighted = mergeTargetID == self?.cardID
                }
                .store(in: &cancellables)
        }
    }

    private func refreshFromWorkspace(now: Date) {
        config = workspaceController.config
        let card = workspaceController.card(for: cardID)
        pages = card?.pages ?? []
        selectedPageID = card?.selectedPageID
        overviewCards = workspaceController.overviewCards(currentCardID: cardID, now: now)
        content = engine.generateContent(config: config, page: currentPage, now: now)
        lastDayStamp = AppStateStore.dayStamp(from: now)
    }

    private func scheduleRefreshTimer() {
        let timer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        refreshTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func tick() {
        let dayStamp = AppStateStore.dayStamp(from: Date())
        if dayStamp != lastDayStamp {
            refreshFromWorkspace(now: Date())
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }
}

import Foundation
import SwiftUI

@MainActor
final class CardViewModel: ObservableObject {
    @Published private(set) var config: CardConfig
    @Published private(set) var content: CardContent
    @Published private(set) var pages: [CountdownPage]
    @Published private(set) var selectedPageID: UUID?

    private let engine = CountdownEngine()
    private let pagesStore = CountdownPagesStore()
    private var refreshTimer: Timer?
    private var lastDayStamp: String

    init() {
        let now = Date()
        let loadedConfig = engine.loadConfig()
        let document = pagesStore.load(config: loadedConfig, now: now)
        let selected = CardViewModel.resolveSelectedPageID(from: document)
        let page = CardViewModel.resolveCurrentPage(from: document.pages, selectedPageID: selected, fallbackConfig: loadedConfig, now: now)

        self.config = loadedConfig
        self.pages = document.pages
        self.selectedPageID = selected
        self.content = engine.generateContent(config: loadedConfig, page: page, now: now)
        self.lastDayStamp = AppStateStore.dayStamp(from: now)
        scheduleRefreshTimer()
    }

    var panelSize: CGSize {
        CGSize(width: CGFloat(config.panelWidth), height: CGFloat(config.panelHeight))
    }

    var panelPosition: CGPoint {
        CGPoint(x: CGFloat(config.panelX), y: CGFloat(config.panelY))
    }

    var currentPage: CountdownPage {
        CardViewModel.resolveCurrentPage(from: pages, selectedPageID: selectedPageID, fallbackConfig: config, now: Date())
    }

    var canDeleteCurrentPage: Bool {
        pages.count > 1
    }

    func reroll() {
        engine.reroll()
        reload(forceConfig: false)
    }

    func reload(forceConfig: Bool = true) {
        let now = Date()
        if forceConfig {
            config = engine.loadConfig()
        }

        let document = pagesStore.load(config: config, now: now)
        pages = document.pages
        selectedPageID = CardViewModel.resolveSelectedPageID(from: document)
        content = engine.generateContent(config: config, page: currentPage, now: now)
        lastDayStamp = AppStateStore.dayStamp(from: now)
    }

    func selectPage(id: UUID) {
        guard pages.contains(where: { $0.id == id }) else { return }
        selectedPageID = id
        persistPages()
        reload(forceConfig: false)
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
        pagesStore.draft(for: currentPage)
    }

    func beginCreatingPage() -> CountdownPageDraft {
        pagesStore.newDraft(relativeTo: currentPage, now: Date())
    }

    func savePage(from draft: CountdownPageDraft) {
        let page = pagesStore.normalizedPage(from: draft)
        if let index = pages.firstIndex(where: { $0.id == page.id }) {
            pages[index] = page
        } else {
            let insertionIndex = (pages.firstIndex(where: { $0.id == selectedPageID }) ?? (pages.count - 1)) + 1
            pages.insert(page, at: max(0, min(insertionIndex, pages.count)))
        }
        selectedPageID = page.id
        persistPages()
        reload(forceConfig: false)
    }

    func deleteCurrentPage() {
        guard canDeleteCurrentPage else { return }
        let currentID = currentPage.id
        guard let index = pages.firstIndex(where: { $0.id == currentID }) else { return }
        pages.remove(at: index)
        let fallbackIndex = min(index, max(0, pages.count - 1))
        selectedPageID = pages[fallbackIndex].id
        persistPages()
        reload(forceConfig: false)
    }

    private func persistPages() {
        let document = CountdownPagesDocument(selectedPageID: selectedPageID, pages: pages)
        pagesStore.save(document)
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
            reload(forceConfig: false)
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }

    private static func resolveSelectedPageID(from document: CountdownPagesDocument) -> UUID? {
        if let selected = document.selectedPageID, document.pages.contains(where: { $0.id == selected }) {
            return selected
        }
        return document.pages.first?.id
    }

    private static func resolveCurrentPage(from pages: [CountdownPage], selectedPageID: UUID?, fallbackConfig: CardConfig, now: Date) -> CountdownPage {
        if let selectedPageID, let page = pages.first(where: { $0.id == selectedPageID }) {
            return page
        }
        if let first = pages.first {
            return first
        }
        return CountdownPagesStore().load(config: fallbackConfig, now: now).pages.first ?? CountdownPage(
            title: fallbackConfig.titleLine,
            targetDate: now
        )
    }
}

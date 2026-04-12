import Foundation
import Combine

@MainActor
final class WorkspaceController: ObservableObject {
    @Published private(set) var config: CardConfig
    @Published private(set) var workspace: CountdownWorkspaceDocument
    @Published private(set) var contentRevision: Int = 0

    private let store = CountdownWorkspaceStore()
    private let engine = CountdownEngine()
    private let calendar = Calendar(identifier: .gregorian)

    init(now: Date = Date()) {
        let loadedConfig = engine.loadConfig()
        self.config = loadedConfig
        self.workspace = store.load(config: loadedConfig, now: now)
    }

    var cards: [CountdownCardDocument] {
        workspace.cards
    }

    func card(for cardID: UUID) -> CountdownCardDocument? {
        workspace.cards.first(where: { $0.id == cardID })
    }

    func currentPage(for cardID: UUID, now: Date = Date()) -> CountdownPage {
        if let card = card(for: cardID), let page = currentPage(in: card) {
            return page
        }
        return store.defaultCard(config: config, now: now).pages[0]
    }

    func focusCard(id: UUID?) {
        guard id == nil || workspace.cards.contains(where: { $0.id == id }) else { return }
        updateWorkspace { workspace in
            workspace.focusedCardID = id ?? workspace.cards.first?.id
        }
    }

    func reloadConfig(now: Date = Date()) {
        config = engine.loadConfig()
        let normalized = store.normalized(workspace, config: config, now: now)
        workspace = normalized
        persistWorkspace()
        contentRevision &+= 1
    }

    func rerollToday(now: Date = Date()) {
        engine.reroll(for: now)
        contentRevision &+= 1
    }

    func setCardOpacity(_ opacity: Double) {
        let clamped = min(max(opacity, 0.82), 1.0)
        guard abs(config.cardOpacity - clamped) > 0.001 else { return }
        var next = config
        next.cardOpacity = clamped
        config = next
        persistConfig()
    }

    func selectPage(cardID: UUID, pageID: UUID) {
        updateCard(cardID) { card in
            guard card.pages.contains(where: { $0.id == pageID }) else { return }
            card.selectedPageID = pageID
        }
        focusCard(id: cardID)
    }

    func beginEditingCurrentPage(in cardID: UUID) -> CountdownPageDraft {
        store.draft(for: currentPage(for: cardID))
    }

    func beginCreatingPage(in cardID: UUID, now: Date = Date()) -> CountdownPageDraft {
        store.newDraft(relativeTo: currentPage(in: card(for: cardID)), now: now)
    }

    func savePage(in cardID: UUID, from draft: CountdownPageDraft) {
        let page = store.normalizedPage(from: draft)
        updateCard(cardID) { card in
            if let index = card.pages.firstIndex(where: { $0.id == page.id }) {
                card.pages[index] = page
            } else {
                let insertionIndex = (card.pages.firstIndex(where: { $0.id == card.selectedPageID }) ?? (card.pages.count - 1)) + 1
                card.pages.insert(page, at: max(0, min(insertionIndex, card.pages.count)))
            }
            card.selectedPageID = page.id
        }
        focusCard(id: cardID)
    }

    func deleteCurrentPage(in cardID: UUID) {
        updateCard(cardID) { card in
            guard card.pages.count > 1,
                  let current = currentPage(in: card),
                  let index = card.pages.firstIndex(where: { $0.id == current.id }) else { return }

            card.pages.remove(at: index)
            let fallbackIndex = min(index, max(0, card.pages.count - 1))
            card.selectedPageID = card.pages[fallbackIndex].id
        }
    }

    @discardableResult
    func createStandaloneCard(relativeTo cardID: UUID?, now: Date = Date(), frame: SavedCardFrame? = nil) -> UUID {
        let relativePage = cardID.flatMap { currentPage(in: card(for: $0)) }
        let draft = store.newDraft(relativeTo: relativePage, now: now)
        let page = store.normalizedPage(from: draft)
        let card = CountdownCardDocument(pages: [page], selectedPageID: page.id, frame: frame)

        updateWorkspace { workspace in
            if let cardID, let index = workspace.cards.firstIndex(where: { $0.id == cardID }) {
                workspace.cards.insert(card, at: index + 1)
            } else {
                workspace.cards.append(card)
            }
            workspace.focusedCardID = card.id
        }

        return card.id
    }

    @discardableResult
    func detachPage(pageID: UUID, from sourceCardID: UUID, frame: SavedCardFrame? = nil) -> UUID? {
        var detachedPage: CountdownPage?
        var insertionIndex = workspace.cards.count

        updateWorkspace { workspace in
            guard let sourceIndex = workspace.cards.firstIndex(where: { $0.id == sourceCardID }) else { return }
            insertionIndex = sourceIndex + 1
            var sourceCard = workspace.cards[sourceIndex]
            guard sourceCard.pages.count > 1,
                  let pageIndex = sourceCard.pages.firstIndex(where: { $0.id == pageID }) else { return }

            detachedPage = sourceCard.pages.remove(at: pageIndex)
            if sourceCard.selectedPageID == pageID {
                let fallbackIndex = min(pageIndex, max(0, sourceCard.pages.count - 1))
                sourceCard.selectedPageID = sourceCard.pages[fallbackIndex].id
            }
            workspace.cards[sourceIndex] = sourceCard
        }

        guard let detachedPage else { return nil }

        let newCard = CountdownCardDocument(pages: [detachedPage], selectedPageID: detachedPage.id, frame: frame)
        updateWorkspace { workspace in
            workspace.cards.insert(newCard, at: min(insertionIndex, workspace.cards.count))
            workspace.focusedCardID = newCard.id
        }
        return newCard.id
    }

    @discardableResult
    func mergeCard(sourceID: UUID, into targetID: UUID) -> UUID? {
        guard sourceID != targetID else { return nil }

        var merged = false
        updateWorkspace { workspace in
            guard let sourceIndex = workspace.cards.firstIndex(where: { $0.id == sourceID }),
                  let originalTargetIndex = workspace.cards.firstIndex(where: { $0.id == targetID }) else { return }

            let sourceCard = workspace.cards[sourceIndex]
            workspace.cards.remove(at: sourceIndex)

            let targetIndex = sourceIndex < originalTargetIndex ? originalTargetIndex - 1 : originalTargetIndex
            guard workspace.cards.indices.contains(targetIndex) else { return }

            workspace.cards[targetIndex].pages.append(contentsOf: sourceCard.pages)
            let selectedStillValid = workspace.cards[targetIndex].pages.contains(where: { $0.id == workspace.cards[targetIndex].selectedPageID })
            if !selectedStillValid {
                workspace.cards[targetIndex].selectedPageID = workspace.cards[targetIndex].pages.first?.id
            }
            workspace.focusedCardID = targetID
            merged = true
        }
        return merged ? targetID : nil
    }

    func updateCardFrame(cardID: UUID, frame: SavedCardFrame?) {
        updateCard(cardID) { card in
            card.frame = frame
        }
    }

    func overviewCards(currentCardID: UUID, now: Date = Date()) -> [CountdownCardOverview] {
        workspace.cards.map { card in
            let currentPage = currentPage(in: card) ?? store.defaultCard(config: config, now: now).pages[0]
            let pages = card.pages.map { page in
                CountdownOverviewPage(
                    id: page.id,
                    title: page.title,
                    targetDate: page.targetDate,
                    daysRemaining: remainingDays(until: page.targetDate, now: now),
                    isSelected: page.id == card.selectedPageID
                )
            }
            return CountdownCardOverview(
                id: card.id,
                title: currentPage.title,
                targetDate: currentPage.targetDate,
                daysRemaining: remainingDays(until: currentPage.targetDate, now: now),
                pageCount: card.pages.count,
                isFocused: card.id == workspace.focusedCardID,
                isCurrentWindow: card.id == currentCardID,
                pages: pages
            )
        }
    }

    private func updateCard(_ cardID: UUID, mutate: (inout CountdownCardDocument) -> Void) {
        updateWorkspace { workspace in
            guard let index = workspace.cards.firstIndex(where: { $0.id == cardID }) else { return }
            var card = workspace.cards[index]
            mutate(&card)
            card = normalized(card)
            workspace.cards[index] = card
        }
    }

    private func updateWorkspace(_ mutate: (inout CountdownWorkspaceDocument) -> Void) {
        var next = workspace
        mutate(&next)
        next = store.normalized(next, config: config, now: Date())
        workspace = next
        persistWorkspace()
    }

    private func persistWorkspace() {
        store.save(workspace)
    }

    private func persistConfig() {
        engine.saveConfig(config)
    }

    private func normalized(_ card: CountdownCardDocument) -> CountdownCardDocument {
        let selectedPageID = card.pages.contains(where: { $0.id == card.selectedPageID }) ? card.selectedPageID : card.pages.first?.id
        return CountdownCardDocument(id: card.id, pages: card.pages, selectedPageID: selectedPageID, frame: card.frame)
    }

    private func currentPage(in card: CountdownCardDocument?) -> CountdownPage? {
        guard let card else { return nil }
        if let selectedPageID = card.selectedPageID,
           let selected = card.pages.first(where: { $0.id == selectedPageID }) {
            return selected
        }
        return card.pages.first
    }

    private func remainingDays(until targetDate: Date, now: Date) -> Int {
        let today = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: targetDate)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }
}

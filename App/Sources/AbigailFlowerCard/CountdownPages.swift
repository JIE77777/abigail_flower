import Foundation
import CoreGraphics

struct CountdownPage: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var targetDate: Date

    init(id: UUID = UUID(), title: String, targetDate: Date) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
    }
}

struct SavedCardFrame: Codable, Hashable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    init(rect: CGRect) {
        self.init(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height)
    }

    var rect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

struct CountdownCardDocument: Identifiable, Codable, Hashable {
    var id: UUID
    var pages: [CountdownPage]
    var selectedPageID: UUID?
    var frame: SavedCardFrame?

    init(id: UUID = UUID(), pages: [CountdownPage], selectedPageID: UUID? = nil, frame: SavedCardFrame? = nil) {
        self.id = id
        self.pages = pages
        self.selectedPageID = selectedPageID
        self.frame = frame
    }
}

struct CountdownWorkspaceDocument: Codable, Hashable {
    var focusedCardID: UUID?
    var cards: [CountdownCardDocument]
}

private struct LegacyCountdownPagesDocument: Codable {
    var selectedPageID: UUID?
    var pages: [CountdownPage]
}

struct CountdownPageDraft {
    var sourcePageID: UUID?
    var title: String
    var targetDate: Date
    var isNew: Bool
}

struct CountdownOverviewPage: Identifiable, Hashable {
    var id: UUID
    var title: String
    var targetDate: Date
    var daysRemaining: Int
    var isSelected: Bool
}

struct CountdownCardOverview: Identifiable, Hashable {
    var id: UUID
    var title: String
    var targetDate: Date
    var daysRemaining: Int
    var pageCount: Int
    var isFocused: Bool
    var isCurrentWindow: Bool
    var pages: [CountdownOverviewPage]
}

extension AbigailPaths {
    static let workspaceFile = supportDirectory.appendingPathComponent("countdown_workspace.json")
    static let legacyPagesFile = supportDirectory.appendingPathComponent("countdown_pages.json")
    static let legacyPagesArchiveFile = supportDirectory.appendingPathComponent("countdown_pages.legacy.json")
}

final class CountdownWorkspaceStore {
    private let calendar = Calendar(identifier: .gregorian)
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func load(config: CardConfig, now: Date = Date()) -> CountdownWorkspaceDocument {
        SupportBootstrap.ensureSupportFiles()

        if let data = try? Data(contentsOf: AbigailPaths.workspaceFile),
           let decoded = try? decoder.decode(CountdownWorkspaceDocument.self, from: data) {
            let sanitized = normalized(decoded, config: config, now: now)
            save(sanitized)
            return sanitized
        }

        if let legacyData = try? Data(contentsOf: AbigailPaths.legacyPagesFile),
           let legacy = try? decoder.decode(LegacyCountdownPagesDocument.self, from: legacyData) {
            let migrated = normalized(migrate(legacy: legacy, config: config, now: now), config: config, now: now)
            save(migrated)
            archiveLegacyFileIfNeeded()
            return migrated
        }

        let fallback = defaultWorkspace(config: config, now: now)
        save(fallback)
        return fallback
    }

    func save(_ workspace: CountdownWorkspaceDocument) {
        SupportBootstrap.ensureSupportFiles()
        guard let data = try? encoder.encode(workspace) else { return }
        try? data.write(to: AbigailPaths.workspaceFile, options: [.atomic])
    }

    func draft(for page: CountdownPage) -> CountdownPageDraft {
        CountdownPageDraft(
            sourcePageID: page.id,
            title: page.title,
            targetDate: normalize(page.targetDate),
            isNew: false
        )
    }

    func newDraft(relativeTo page: CountdownPage?, now: Date = Date()) -> CountdownPageDraft {
        let base = normalize(page?.targetDate ?? now)
        let suggestedDate = calendar.date(byAdding: .day, value: 30, to: base) ?? base
        return CountdownPageDraft(
            sourcePageID: nil,
            title: "新的日期",
            targetDate: suggestedDate,
            isNew: true
        )
    }

    func normalizedPage(from draft: CountdownPageDraft) -> CountdownPage {
        CountdownPage(
            id: draft.sourcePageID ?? UUID(),
            title: normalizedTitle(draft.title),
            targetDate: normalize(draft.targetDate)
        )
    }

    func normalized(_ workspace: CountdownWorkspaceDocument, config: CardConfig, now: Date) -> CountdownWorkspaceDocument {
        var seenCardIDs = Set<UUID>()
        let sanitizedCards = workspace.cards.compactMap { rawCard -> CountdownCardDocument? in
            guard seenCardIDs.insert(rawCard.id).inserted else { return nil }

            let pages = rawCard.pages.map { page in
                CountdownPage(
                    id: page.id,
                    title: normalizedTitle(page.title),
                    targetDate: normalize(page.targetDate)
                )
            }

            guard !pages.isEmpty else { return nil }

            let selectedPageID = pages.contains(where: { $0.id == rawCard.selectedPageID })
                ? rawCard.selectedPageID
                : pages.first?.id

            return CountdownCardDocument(
                id: rawCard.id,
                pages: pages,
                selectedPageID: selectedPageID,
                frame: rawCard.frame
            )
        }

        let cards = sanitizedCards.isEmpty ? [defaultCard(config: config, now: now)] : sanitizedCards
        let focusedCardID = cards.contains(where: { $0.id == workspace.focusedCardID })
            ? workspace.focusedCardID
            : cards.first?.id

        return CountdownWorkspaceDocument(focusedCardID: focusedCardID, cards: cards)
    }

    func defaultCard(config: CardConfig, now: Date, frame: SavedCardFrame? = nil) -> CountdownCardDocument {
        let page = CountdownPage(
            title: normalizedTitle(config.titleLine),
            targetDate: nextDefaultTargetDate(config: config, now: now)
        )
        return CountdownCardDocument(pages: [page], selectedPageID: page.id, frame: frame)
    }

    private func defaultWorkspace(config: CardConfig, now: Date) -> CountdownWorkspaceDocument {
        let card = defaultCard(config: config, now: now)
        return CountdownWorkspaceDocument(focusedCardID: card.id, cards: [card])
    }

    private func migrate(legacy: LegacyCountdownPagesDocument, config: CardConfig, now: Date) -> CountdownWorkspaceDocument {
        let pages = legacy.pages.map { page in
            CountdownPage(id: page.id, title: normalizedTitle(page.title), targetDate: normalize(page.targetDate))
        }
        let card = CountdownCardDocument(
            pages: pages.isEmpty ? [defaultCard(config: config, now: now).pages[0]] : pages,
            selectedPageID: pages.contains(where: { $0.id == legacy.selectedPageID }) ? legacy.selectedPageID : pages.first?.id,
            frame: nil
        )
        return CountdownWorkspaceDocument(focusedCardID: card.id, cards: [card])
    }

    private func archiveLegacyFileIfNeeded() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: AbigailPaths.legacyPagesFile.path) else { return }

        if fm.fileExists(atPath: AbigailPaths.legacyPagesArchiveFile.path) {
            try? fm.removeItem(at: AbigailPaths.legacyPagesFile)
            return
        }

        try? fm.moveItem(at: AbigailPaths.legacyPagesFile, to: AbigailPaths.legacyPagesArchiveFile)
    }

    private func normalize(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func normalizedTitle(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "新的日期" : trimmed
    }

    private func nextDefaultTargetDate(config: CardConfig, now: Date) -> Date {
        let today = normalize(now)
        var components = calendar.dateComponents([.year], from: today)
        components.month = config.targetMonth
        components.day = config.targetDay
        var target = calendar.date(from: components) ?? today
        if today > target {
            components.year = (components.year ?? calendar.component(.year, from: today)) + 1
            target = calendar.date(from: components) ?? target
        }
        return normalize(target)
    }
}

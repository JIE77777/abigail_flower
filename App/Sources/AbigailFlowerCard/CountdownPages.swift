import Foundation

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

struct CountdownPagesDocument: Codable {
    var selectedPageID: UUID?
    var pages: [CountdownPage]
}

struct CountdownPageDraft {
    var sourcePageID: UUID?
    var title: String
    var targetDate: Date
    var isNew: Bool
}

extension AbigailPaths {
    static let pagesFile = supportDirectory.appendingPathComponent("countdown_pages.json")
}

final class CountdownPagesStore {
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

    func load(config: CardConfig, now: Date = Date()) -> CountdownPagesDocument {
        SupportBootstrap.ensureSupportFiles()
        guard
            let data = try? Data(contentsOf: AbigailPaths.pagesFile),
            let decoded = try? decoder.decode(CountdownPagesDocument.self, from: data)
        else {
            let fallback = defaultDocument(config: config, now: now)
            save(fallback)
            return fallback
        }

        let sanitized = sanitize(decoded, config: config, now: now)
        save(sanitized)
        return sanitized
    }

    func save(_ document: CountdownPagesDocument) {
        SupportBootstrap.ensureSupportFiles()
        guard let data = try? encoder.encode(document) else { return }
        try? data.write(to: AbigailPaths.pagesFile, options: [.atomic])
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

    private func defaultDocument(config: CardConfig, now: Date) -> CountdownPagesDocument {
        let page = CountdownPage(
            title: normalizedTitle(config.titleLine),
            targetDate: nextDefaultTargetDate(config: config, now: now)
        )
        return CountdownPagesDocument(selectedPageID: page.id, pages: [page])
    }

    private func sanitize(_ document: CountdownPagesDocument, config: CardConfig, now: Date) -> CountdownPagesDocument {
        var pages = document.pages.map { page in
            CountdownPage(
                id: page.id,
                title: normalizedTitle(page.title),
                targetDate: normalize(page.targetDate)
            )
        }

        if pages.isEmpty {
            return defaultDocument(config: config, now: now)
        }

        let selected = pages.contains(where: { $0.id == document.selectedPageID })
            ? document.selectedPageID
            : pages.first?.id

        return CountdownPagesDocument(selectedPageID: selected, pages: pages)
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

import Foundation

struct CardConfig {
    var titleLine: String = "距离 8.31"
    var targetMonth: Int = 8
    var targetDay: Int = 31
    var taglineMode: String = "daily_random"
    var fallbackTagline: String = "你今天是最棒的！"
    var taglineCountMin: Int = 1
    var taglineCountMax: Int = 1
    var taglineWeights: [String: Int] = [
        "bright": 3,
        "reminders": 2,
        "playful": 2,
        "wendy": 2,
        "cookie": 5,
    ]
    var easterEggsEnabled: Bool = true
    var easterEggDailyChance: Int = 28
    var easterWeights: [String: Int] = [
        "always": 1,
        "thursday": 2,
        "weekend": 2,
        "august": 3,
        "final30": 4,
        "final10": 6,
        "milestones": 6,
        "cookie": 3,
    ]
    var panelX: Double = 1120
    var panelY: Double = 84
    var panelWidth: Double = 400
    var panelHeight: Double = 322
    var showEnglishFirst: Bool = true
    var cardOpacity: Double = 0.97
}

struct CardEntry: Identifiable, Hashable {
    let id = UUID()
    let lines: [String]
}

struct CardContent {
    let title: String
    let entries: [CardEntry]
    let daysRemaining: Int
}

enum AbigailPaths {
    static let fileManager = FileManager.default
    static let supportDirectory = fileManager.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/AbigailFlowerCard", isDirectory: true)
    static let stateDirectory = supportDirectory.appendingPathComponent("state", isDirectory: true)
    static let configFile = supportDirectory.appendingPathComponent("countdown.env")
    static let rerollTokenFile = stateDirectory.appendingPathComponent("reroll_seed.txt")
    static let taglinesDirectory = supportDirectory.appendingPathComponent("taglines.d", isDirectory: true)
    static let easterEggsDirectory = supportDirectory.appendingPathComponent("easter_eggs.d", isDirectory: true)

    static func bundledDefaultsDirectory() -> URL {
        Bundle.main.resourceURL!.appendingPathComponent("Defaults", isDirectory: true)
    }

    static func bundledTaglinesDirectory() -> URL {
        bundledDefaultsDirectory().appendingPathComponent("taglines.d", isDirectory: true)
    }

    static func bundledEasterEggsDirectory() -> URL {
        bundledDefaultsDirectory().appendingPathComponent("easter_eggs.d", isDirectory: true)
    }

    static func bundledConfigFile() -> URL {
        bundledDefaultsDirectory().appendingPathComponent("countdown.env.example")
    }

    static func bundledFlowerIcon() -> URL? {
        Bundle.main.resourceURL?.appendingPathComponent("Defaults/icons/abigail_flower_level3.png")
    }
}

final class SupportBootstrap {
    static func ensureSupportFiles() {
        let fm = FileManager.default
        try? fm.createDirectory(at: AbigailPaths.supportDirectory, withIntermediateDirectories: true)
        try? fm.createDirectory(at: AbigailPaths.stateDirectory, withIntermediateDirectories: true)
        try? fm.createDirectory(at: AbigailPaths.taglinesDirectory, withIntermediateDirectories: true)
        try? fm.createDirectory(at: AbigailPaths.easterEggsDirectory, withIntermediateDirectories: true)

        copyIfMissing(from: AbigailPaths.bundledConfigFile(), to: AbigailPaths.configFile)
        copyDirectoryContentsIfMissing(from: AbigailPaths.bundledTaglinesDirectory(), to: AbigailPaths.taglinesDirectory)
        copyDirectoryContentsIfMissing(from: AbigailPaths.bundledEasterEggsDirectory(), to: AbigailPaths.easterEggsDirectory)
    }

    private static func copyIfMissing(from source: URL, to target: URL) {
        guard FileManager.default.fileExists(atPath: source.path) else { return }
        guard !FileManager.default.fileExists(atPath: target.path) else { return }
        try? FileManager.default.copyItem(at: source, to: target)
    }

    private static func copyDirectoryContentsIfMissing(from sourceDir: URL, to targetDir: URL) {
        guard let files = try? FileManager.default.contentsOfDirectory(at: sourceDir, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files {
            let target = targetDir.appendingPathComponent(file.lastPathComponent)
            copyIfMissing(from: file, to: target)
        }
    }
}

struct EnvLoader {
    static func load(url: URL) -> [String: String] {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }
        var values: [String: String] = [:]
        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") { continue }
            guard let idx = line.firstIndex(of: "=") else { continue }
            let key = String(line[..<idx]).trimmingCharacters(in: .whitespacesAndNewlines)
            var value = String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2 {
                value.removeFirst()
                value.removeLast()
            }
            values[key] = value
        }
        return values
    }
}

struct AppStateStore {
    func currentRerollToken(for date: Date = Date()) -> String? {
        guard let text = try? String(contentsOf: AbigailPaths.rerollTokenFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty,
              let separator = text.range(of: "::") else {
            return nil
        }
        let datePart = String(text[..<separator.lowerBound])
        let tokenPart = String(text[separator.upperBound...])
        return datePart == Self.dayStamp(from: date) ? tokenPart : nil
    }

    @discardableResult
    func saveNewRerollToken(for date: Date = Date()) -> String {
        let token = "\(Int(Date().timeIntervalSince1970 * 1000))-\(String(UUID().uuidString.prefix(8)))"
        let text = "\(Self.dayStamp(from: date))::\(token)"
        try? text.write(to: AbigailPaths.rerollTokenFile, atomically: true, encoding: .utf8)
        return token
    }

    static func dayStamp(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: String) {
        let hash = SeededGenerator.fnv1a64(seed)
        self.state = hash == 0 ? 0x9E3779B97F4A7C15 : hash
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    private static func fnv1a64(_ string: String) -> UInt64 {
        let prime: UInt64 = 1099511628211
        var hash: UInt64 = 14695981039346656037
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= prime
        }
        return hash
    }
}

struct WeightedCategory {
    var entries: [CardEntry]
    let weight: Int
}

final class CountdownEngine {
    private let calendar = Calendar(identifier: .gregorian)
    private let stateStore = AppStateStore()

    func loadConfig() -> CardConfig {
        SupportBootstrap.ensureSupportFiles()
        let env = EnvLoader.load(url: AbigailPaths.configFile)
        var config = CardConfig()
        config.titleLine = env["TITLE_LINE"] ?? config.titleLine
        config.targetMonth = Int(env["TARGET_MONTH"] ?? "") ?? config.targetMonth
        config.targetDay = Int(env["TARGET_DAY"] ?? "") ?? config.targetDay
        config.taglineMode = env["TAGLINE_MODE"] ?? config.taglineMode
        config.fallbackTagline = env["TAGLINE"] ?? config.fallbackTagline
        config.taglineCountMin = Int(env["TAGLINE_COUNT_MIN"] ?? "") ?? config.taglineCountMin
        config.taglineCountMax = Int(env["TAGLINE_COUNT_MAX"] ?? "") ?? config.taglineCountMax
        config.easterEggsEnabled = (env["EASTER_EGGS_ENABLED"] ?? "1") != "0"
        config.easterEggDailyChance = Int(env["EASTER_EGG_DAILY_CHANCE"] ?? "") ?? config.easterEggDailyChance
        config.panelX = Double(env["PANEL_X"] ?? "") ?? config.panelX
        config.panelY = Double(env["PANEL_Y"] ?? "") ?? config.panelY
        config.panelWidth = Double(env["PANEL_WIDTH"] ?? "") ?? config.panelWidth
        config.panelHeight = Double(env["PANEL_HEIGHT"] ?? "") ?? config.panelHeight
        config.showEnglishFirst = (env["SHOW_ENGLISH_FIRST"] ?? "1") != "0"
        config.cardOpacity = Double(env["CARD_OPACITY"] ?? "") ?? config.cardOpacity

        for key in config.taglineWeights.keys {
            let envKey = "TAGLINE_WEIGHT_\(key.uppercased())"
            if let raw = env[envKey], let value = Int(raw) {
                config.taglineWeights[key] = max(0, value)
            }
        }

        for key in config.easterWeights.keys {
            let envKey = "EASTER_WEIGHT_\(key.uppercased())"
            if let raw = env[envKey], let value = Int(raw) {
                config.easterWeights[key] = max(0, value)
            }
        }

        config.taglineCountMin = max(1, config.taglineCountMin)
        config.taglineCountMax = max(config.taglineCountMin, config.taglineCountMax)
        config.easterEggDailyChance = min(max(config.easterEggDailyChance, 0), 100)
        return config
    }

    func generateContent(config: CardConfig, now: Date = Date()) -> CardContent {
        let today = calendar.startOfDay(for: now)
        var components = calendar.dateComponents([.year], from: today)
        components.month = config.targetMonth
        components.day = config.targetDay
        var target = calendar.date(from: components) ?? today
        if today > target {
            components.year = (components.year ?? calendar.component(.year, from: today)) + 1
            target = calendar.date(from: components) ?? target
        }

        let days = calendar.dateComponents([.day], from: today, to: target).day ?? 0
        let seedBase = "\(AppStateStore.dayStamp(from: today))::\(config.titleLine)"
        let generatorMode = config.taglineMode.lowercased()

        var subtitleEntries: [CardEntry] = []
        if generatorMode == "fixed" {
            subtitleEntries = [normalizeEntry(config.fallbackTagline, showEnglishFirst: config.showEnglishFirst)]
        } else {
            if generatorMode == "random" {
                var generator = SystemRandomNumberGenerator()
                subtitleEntries = pickTaglines(config: config, using: &generator)
            } else {
                let override = stateStore.currentRerollToken(for: today)
                let material = override.map { seedBase + "::" + $0 } ?? seedBase
                var generator = SeededGenerator(seed: material)
                subtitleEntries = pickTaglines(config: config, using: &generator)
            }
            if subtitleEntries.isEmpty {
                subtitleEntries = [normalizeEntry(config.fallbackTagline, showEnglishFirst: config.showEnglishFirst)]
            }
        }

        var allEntries = subtitleEntries
        if config.easterEggsEnabled {
            switch generatorMode {
            case "random":
                var generator = SystemRandomNumberGenerator()
                if let extra = pickEasterEgg(config: config, daysRemaining: days, today: today, using: &generator) {
                    allEntries.append(extra)
                }
            default:
                let override = stateStore.currentRerollToken(for: today)
                let material = override.map { seedBase + "::" + $0 } ?? seedBase
                var generator = SeededGenerator(seed: material + "::easter")
                if let extra = pickEasterEgg(config: config, daysRemaining: days, today: today, using: &generator) {
                    allEntries.append(extra)
                }
            }
        }

        return CardContent(title: config.titleLine, entries: allEntries, daysRemaining: days)
    }

    @discardableResult
    func reroll(for date: Date = Date()) -> String {
        stateStore.saveNewRerollToken(for: date)
    }

    private func pickTaglines<G: RandomNumberGenerator>(config: CardConfig, using generator: inout G) -> [CardEntry] {
        var categories = loadCategories(from: AbigailPaths.taglinesDirectory, weights: config.taglineWeights, showEnglishFirst: config.showEnglishFirst)
        let total = categories.reduce(0) { $0 + $1.entries.count }
        guard total > 0 else { return [] }
        let desiredCount = min(total, Int.random(in: config.taglineCountMin...config.taglineCountMax, using: &generator))
        var results: [CardEntry] = []

        while results.count < desiredCount {
            let candidates = categories.enumerated().filter { !$0.element.entries.isEmpty && $0.element.weight > 0 }
            guard !candidates.isEmpty else { break }
            let totalWeight = candidates.reduce(0) { $0 + $1.element.weight }
            let pick = Int.random(in: 0..<(max(totalWeight, 1)), using: &generator)
            var cursor = 0
            var selectedIndex = candidates[0].offset
            for candidate in candidates {
                cursor += candidate.element.weight
                if pick < cursor {
                    selectedIndex = candidate.offset
                    break
                }
            }
            let entryIndex = Int.random(in: 0..<categories[selectedIndex].entries.count, using: &generator)
            results.append(categories[selectedIndex].entries.remove(at: entryIndex))
        }
        return results
    }

    private func pickEasterEgg<G: RandomNumberGenerator>(config: CardConfig, daysRemaining: Int, today: Date, using generator: inout G) -> CardEntry? {
        guard Int.random(in: 1...100, using: &generator) <= config.easterEggDailyChance else {
            return nil
        }
        var allowedWeights: [String: Int] = [:]
        for (name, weight) in config.easterWeights {
            if matchesEasterCondition(name: name, today: today, daysRemaining: daysRemaining) {
                allowedWeights[name] = weight
            }
        }
        var categories = loadCategories(from: AbigailPaths.easterEggsDirectory, weights: allowedWeights, showEnglishFirst: config.showEnglishFirst)
        let candidates = categories.enumerated().filter { !$0.element.entries.isEmpty && $0.element.weight > 0 }
        guard !candidates.isEmpty else { return nil }
        let totalWeight = candidates.reduce(0) { $0 + $1.element.weight }
        let pick = Int.random(in: 0..<(max(totalWeight, 1)), using: &generator)
        var cursor = 0
        var selectedIndex = candidates[0].offset
        for candidate in candidates {
            cursor += candidate.element.weight
            if pick < cursor {
                selectedIndex = candidate.offset
                break
            }
        }
        let entryIndex = Int.random(in: 0..<categories[selectedIndex].entries.count, using: &generator)
        return categories[selectedIndex].entries[entryIndex]
    }

    private func loadCategories(from directory: URL, weights: [String: Int], showEnglishFirst: Bool) -> [WeightedCategory] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }
        return files
            .filter { $0.pathExtension == "txt" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { url in
                let name = url.deletingPathExtension().lastPathComponent
                let weight = max(0, weights[name] ?? 1)
                let entries = loadEntries(from: url, showEnglishFirst: showEnglishFirst)
                guard !entries.isEmpty else { return nil }
                return WeightedCategory(entries: entries, weight: weight)
            }
    }

    private func loadEntries(from fileURL: URL, showEnglishFirst: Bool) -> [CardEntry] {
        guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return []
        }
        return text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            .map { normalizeEntry($0, showEnglishFirst: showEnglishFirst) }
    }

    private func normalizeEntry(_ raw: String, showEnglishFirst: Bool) -> CardEntry {
        let parts = raw
            .components(separatedBy: " || ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if parts.count == 2 && !showEnglishFirst {
            return CardEntry(lines: [parts[1], parts[0]])
        }
        return CardEntry(lines: parts.isEmpty ? [raw] : parts)
    }

    private func matchesEasterCondition(name: String, today: Date, daysRemaining: Int) -> Bool {
        switch name {
        case "always":
            return true
        case "thursday":
            return calendar.component(.weekday, from: today) == 5
        case "weekend":
            let weekday = calendar.component(.weekday, from: today)
            return weekday == 1 || weekday == 7
        case "august":
            return calendar.component(.month, from: today) == 8
        case "final30":
            return (1...30).contains(daysRemaining)
        case "final10":
            return (1...10).contains(daysRemaining)
        case "milestones":
            return [200, 160, 150, 120, 100, 60, 50, 30, 10, 7, 3, 1].contains(daysRemaining)
        case "cookie":
            return true
        default:
            return false
        }
    }
}

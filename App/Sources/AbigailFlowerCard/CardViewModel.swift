import Foundation
import SwiftUI

@MainActor
final class CardViewModel: ObservableObject {
    @Published private(set) var config: CardConfig
    @Published private(set) var content: CardContent

    private let engine = CountdownEngine()
    private var refreshTimer: Timer?
    private var lastDayStamp: String

    init() {
        let loadedConfig = engine.loadConfig()
        self.config = loadedConfig
        let now = Date()
        self.content = engine.generateContent(config: loadedConfig, now: now)
        self.lastDayStamp = AppStateStore.dayStamp(from: now)
        scheduleRefreshTimer()
    }

    var panelSize: CGSize {
        CGSize(width: CGFloat(config.panelWidth), height: CGFloat(config.panelHeight))
    }

    var panelPosition: CGPoint {
        CGPoint(x: CGFloat(config.panelX), y: CGFloat(config.panelY))
    }

    func reroll() {
        engine.reroll()
        reload(forceConfig: false)
    }

    func reload(forceConfig: Bool = true) {
        if forceConfig {
            config = engine.loadConfig()
        }
        let now = Date()
        content = engine.generateContent(config: config, now: now)
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
            reload(forceConfig: false)
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }
}

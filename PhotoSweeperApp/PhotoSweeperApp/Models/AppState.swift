import SwiftUI
import PhotoSweeperCore

/// Global app state
@MainActor
class AppState: ObservableObject {
    @Published var currentScreen: Screen = .onboarding
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    // Scan state
    @Published var scanProgress: ScanProgress?
    @Published var isScanning = false

    // Results
    @Published var groups: [Group] = []
    @Published var heuristics: [HeuristicResult] = []
    @Published var assets: [String: Asset] = [:]

    // Selection state
    @Published var selectedCount = 0
    @Published var estimatedSavings: Int64 = 0

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        currentScreen = .scan
    }

    func startScan() {
        currentScreen = .scan
        isScanning = true
    }

    func showResults() {
        currentScreen = .results
        isScanning = false
        updateSelectionStats()
    }

    func showPaywall() {
        currentScreen = .paywall
    }

    func updateSelectionStats() {
        // Count selected items
        let groupSelected = groups.flatMap { $0.membersToDelete }.count
        let heuristicSelected = heuristics.filter { $0.isSelected }.count
        selectedCount = groupSelected + heuristicSelected

        // Calculate savings
        let sweeper = Sweeper()
        estimatedSavings = sweeper.estimatedSavings(
            groups: groups,
            heuristics: heuristics,
            assets: assets
        )
    }

    func reset() {
        groups = []
        heuristics = []
        assets = [:]
        selectedCount = 0
        estimatedSavings = 0
        scanProgress = nil
        currentScreen = .scan
    }

    enum Screen {
        case onboarding
        case scan
        case results
        case paywall
    }
}

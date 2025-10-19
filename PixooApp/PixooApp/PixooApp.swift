import SwiftUI
import UserNotifications

@main
struct PhotoSweeperApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var storeKit = StoreKitService()

    init() {
        // Request notification authorization on launch
        NotificationService.shared.requestAuthorization()

        // Register background tasks
        BackgroundTaskService.shared.registerTasks()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(storeKit)
                .onAppear {
                    // Check if onboarding needed
                    if !appState.hasCompletedOnboarding {
                        appState.currentScreen = .onboarding
                    }
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        switch appState.currentScreen {
        case .onboarding:
            OnboardingView()
        case .scan:
            ScanView()
        case .results:
            ResultsView()
        case .paywall:
            PaywallView()
        }
    }
}

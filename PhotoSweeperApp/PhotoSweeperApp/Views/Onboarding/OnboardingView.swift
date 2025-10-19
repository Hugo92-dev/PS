import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Welcome & Promise
            WelcomePage()
                .tag(0)

            // Page 2: Permission Request
            PermissionPage()
                .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

struct WelcomePage: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "photo.stack.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.blue.gradient)

            VStack(spacing: 16) {
                Text("Bienvenue dans PhotoSweeper")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Libérez de l'espace en supprimant les doublons et photos inutiles")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "checkmark.shield.fill", title: "100% privé", description: "Tout reste sur votre appareil")
                FeatureRow(icon: "arrow.clockwise", title: "Restaurable", description: "30 jours dans 'Supprimés récemment'")
                FeatureRow(icon: "sparkles", title: "Intelligent", description: "Détection automatique des doublons et similaires")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: {
                withAnimation {
                    appState.currentScreen = .onboarding
                }
            }) {
                Text("Continuer")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}

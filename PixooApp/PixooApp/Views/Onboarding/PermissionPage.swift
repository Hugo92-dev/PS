import SwiftUI
import Photos

struct PermissionPage: View {
    @EnvironmentObject var appState: AppState
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.green.gradient)

            VStack(spacing: 16) {
                Text("Accès à vos photos")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("PhotoSweeper a besoin d'accéder à votre photothèque pour analyser vos photos")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 16) {
                InfoRow(icon: "lock.shield.fill", text: "Vos photos restent privées sur votre appareil")
                InfoRow(icon: "arrow.uturn.backward.circle.fill", text: "Photos supprimées restaurables pendant 30 jours")
                InfoRow(icon: "hand.raised.fill", text: "Vous contrôlez ce qui est supprimé")
            }
            .padding(.horizontal, 32)

            Spacer()

            if authorizationStatus == .authorized || authorizationStatus == .limited {
                Button(action: {
                    appState.completeOnboarding()
                }) {
                    Text("Commencer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            } else {
                Button(action: {
                    Task {
                        authorizationStatus = await PhotoLibraryManager.shared.requestAuthorization()

                        if authorizationStatus == .authorized || authorizationStatus == .limited {
                            appState.completeOnboarding()
                        }
                    }
                }) {
                    Text("Autoriser l'accès")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }

            if authorizationStatus == .denied || authorizationStatus == .restricted {
                Text("Accès refusé. Allez dans Réglages → PhotoSweeper → Photos pour autoriser l'accès.")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
                .frame(height: 40)
        }
        .onAppear {
            authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    PermissionPage()
        .environmentObject(AppState())
}

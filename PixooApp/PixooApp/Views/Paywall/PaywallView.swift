import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var storeKit: StoreKitService
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.yellow.gradient)

                        Text("Pixoo Pro")
                            .font(.largeTitle.bold())

                        Text("Débloquez la suppression pour libérer **\(Sweeper.formatBytes(appState.estimatedSavings))**")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Features
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(
                            icon: "trash.fill",
                            title: "Suppression illimitée",
                            description: "Supprimez autant de photos que vous voulez"
                        )
                        FeatureRow(
                            icon: "infinity",
                            title: "Achat à vie",
                            description: "Payez une fois, utilisez pour toujours"
                        )
                        FeatureRow(
                            icon: "shield.checkered",
                            title: "Sécurisé",
                            description: "Restauration possible pendant 30 jours"
                        )
                        FeatureRow(
                            icon: "dollarsign.circle.fill",
                            title: "Pas d'abonnement",
                            description: "Aucun frais récurrent, aucune pub"
                        )
                    }
                    .padding(.horizontal)

                    // Price
                    if let product = storeKit.product {
                        VStack(spacing: 12) {
                            Text(product.displayPrice)
                                .font(.system(size: 48, weight: .bold))

                            Text("Achat unique • À vie")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical)
                    }

                    // Purchase button
                    if storeKit.purchaseInProgress {
                        ProgressView()
                            .controlSize(.large)
                    } else {
                        Button(action: {
                            Task {
                                do {
                                    try await storeKit.purchase()
                                    showSuccess = true
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }) {
                            Label("Acheter maintenant", systemImage: "cart.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        Button("Restaurer les achats") {
                            Task {
                                do {
                                    try await storeKit.restorePurchases()
                                    if storeKit.isPro {
                                        showSuccess = true
                                    } else {
                                        errorMessage = "Aucun achat trouvé"
                                        showError = true
                                    }
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    // Legal
                    Text("En achetant, vous acceptez que l'achat soit final. Le partage familial est désactivé pour cet achat à vie individuel.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .navigationTitle("Débloquer Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Retour") {
                        appState.currentScreen = .results
                    }
                }
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showSuccess) {
                DeletionSuccessView()
            }
        }
    }
}

struct DeletionSuccessView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.green.gradient)

            VStack(spacing: 16) {
                Text("Achat réussi !")
                    .font(.largeTitle.bold())

                Text("Vous pouvez maintenant supprimer les photos sélectionnées")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button(action: {
                dismiss()
                // Trigger deletion after purchase
                DeletionService.shared.deleteSelected(
                    groups: appState.groups,
                    heuristics: appState.heuristics
                ) { success in
                    if success {
                        appState.reset()
                    }
                }
            }) {
                Text("Continuer")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(AppState())
        .environmentObject(StoreKitService())
}

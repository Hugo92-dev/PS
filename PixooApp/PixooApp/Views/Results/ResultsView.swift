import SwiftUI
import PixooCore

struct ResultsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tabs
                Picker("", selection: $selectedTab) {
                    Text("Doublons & Similaires").tag(0)
                    Text("Photos inutiles").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Tab content
                TabView(selection: $selectedTab) {
                    DuplicatesTab()
                        .tag(0)

                    UselessPhotosTab()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom bar: Savings + Delete button
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "externaldrive.fill")
                            .foregroundStyle(.green)

                        Text("Vous pouvez libérer **\(Sweeper.formatBytes(appState.estimatedSavings))**")
                            .font(.headline)

                        Spacer()
                    }
                    .padding(.horizontal)

                    Button(action: {
                        appState.showPaywall()
                    }) {
                        Label("Supprimer \(appState.selectedCount) éléments (\(Sweeper.formatBytes(appState.estimatedSavings)))",
                              systemImage: "trash.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(appState.selectedCount > 0 ? Color.red : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(appState.selectedCount == 0)
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Résultats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Nouvelle analyse") {
                        appState.reset()
                    }
                }
            }
            .onAppear {
                appState.updateSelectionStats()
            }
        }
    }
}

#Preview {
    ResultsView()
        .environmentObject({
            let state = AppState()
            state.groups = [
                Group(type: .duplicate, members: [
                    GroupMember(id: "1", fileSize: 1_000_000, resolution: 1_000_000, sharpness: 100, creationDate: Date(), shouldKeep: true, isSelected: false),
                    GroupMember(id: "2", fileSize: 500_000, resolution: 800_000, sharpness: 90, creationDate: Date(), shouldKeep: false, isSelected: true)
                ])
            ]
            state.selectedCount = 5
            state.estimatedSavings = 15_000_000
            return state
        }())
}

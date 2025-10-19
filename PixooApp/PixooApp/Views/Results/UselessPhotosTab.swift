import SwiftUI
import PixooCore

struct UselessPhotosTab: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.heuristics.isEmpty {
            ContentUnavailableView(
                "Aucune photo inutile",
                systemImage: "sparkles",
                description: Text("Toutes vos photos semblent OK !")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                    ForEach(HeuristicLabel.allCases, id: \.self) { label in
                        let filtered = appState.heuristics.filter { $0.labels.contains(label) }

                        if !filtered.isEmpty {
                            Section {
                                ForEach(filtered) { result in
                                    HeuristicCard(result: result)
                                }
                            } header: {
                                HStack {
                                    Label(label.displayName, systemImage: label.icon)
                                        .font(.headline)
                                        .foregroundStyle(.white)

                                    Spacer()

                                    Text("\(filtered.count)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.white.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                .padding()
                                .background(colorForLabel(label).gradient)
                            }
                        }
                    }
                }
            }
        }
    }

    private func colorForLabel(_ label: HeuristicLabel) -> Color {
        switch label {
        case .blur: return .purple
        case .flat: return .gray
        case .black: return .black
        case .white: return .blue
        case .finger: return .orange
        case .burst: return .pink
        }
    }
}

struct HeuristicCard: View {
    @EnvironmentObject var appState: AppState
    let result: HeuristicResult

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            Rectangle()
                .fill(.gray.gradient)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.white.opacity(0.5))
                }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(result.reason)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let asset = appState.assets[result.assetID] {
                    Text(Sweeper.formatBytes(asset.fileSize))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    ForEach(result.labels, id: \.self) { label in
                        Text(label.rawValue.uppercased())
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            // Selection toggle
            Button(action: {
                toggleSelection()
            }) {
                Image(systemName: result.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(result.isSelected ? .red : .gray)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func toggleSelection() {
        if let index = appState.heuristics.firstIndex(where: { $0.id == result.id }) {
            appState.heuristics[index] = HeuristicResult(
                id: result.id,
                assetID: result.assetID,
                labels: result.labels,
                confidence: result.confidence,
                reason: result.reason,
                isSelected: !result.isSelected
            )
            appState.updateSelectionStats()
        }
    }
}

#Preview {
    UselessPhotosTab()
        .environmentObject({
            let state = AppState()
            state.heuristics = [
                HeuristicResult(assetID: "1", labels: [.blur], confidence: 0.8, reason: "Netteté faible (45.2 < 60.0)", isSelected: true),
                HeuristicResult(assetID: "2", labels: [.flat], confidence: 0.75, reason: "Fond quasi-uni (entropie 2.1 < 3.0)", isSelected: true),
                HeuristicResult(assetID: "3", labels: [.black], confidence: 0.9, reason: "Image très sombre (luminance 5.2%)", isSelected: true)
            ]
            state.assets = [
                "1": Asset(id: "1", creationDate: Date(), modificationDate: nil, width: 1000, height: 1000, fileSize: 500_000, mediaType: .image, isFavorite: false, burstIdentifier: nil),
                "2": Asset(id: "2", creationDate: Date(), modificationDate: nil, width: 1200, height: 1200, fileSize: 800_000, mediaType: .image, isFavorite: false, burstIdentifier: nil),
                "3": Asset(id: "3", creationDate: Date(), modificationDate: nil, width: 800, height: 600, fileSize: 200_000, mediaType: .image, isFavorite: false, burstIdentifier: nil)
            ]
            return state
        }())
}

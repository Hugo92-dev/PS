import SwiftUI

struct ScanView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var scanService = ScanService.shared

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: scanService.isScanning ? "photo.stack" : "magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.blue.gradient)
                .symbolEffect(.pulse, isActive: scanService.isScanning)

            VStack(spacing: 16) {
                Text(scanService.isScanning ? "Analyse en cours..." : "Prêt à analyser")
                    .font(.largeTitle.bold())

                if let progress = scanService.progress {
                    Text("\(progress.processedCount) / \(progress.totalCount) photos")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    ProgressView(value: progress.progress)
                        .progressViewStyle(.linear)
                        .frame(width: 250)

                    Text("\(progress.progressPercentage)%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if scanService.isScanning {
                Text("L'analyse continue même si l'app passe en arrière-plan")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
            }

            Spacer()

            if !scanService.isScanning {
                Button(action: {
                    scanService.startScan { groups, heuristics, assets in
                        appState.groups = groups
                        appState.heuristics = heuristics
                        appState.assets = assets
                        appState.showResults()
                    }
                }) {
                    Label("Analyser ma photothèque", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)

                if let progress = scanService.progress, progress.status == .paused {
                    Text("Analyse en pause. Appuyez pour reprendre.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } else {
                Button(action: {
                    scanService.cancelScan()
                }) {
                    Label("Mettre en pause", systemImage: "pause.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }

            Spacer()
                .frame(height: 40)
        }
        .padding()
    }
}

#Preview {
    ScanView()
        .environmentObject(AppState())
}

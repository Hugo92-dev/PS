import SwiftUI
import PixooCore

struct DuplicatesTab: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.groups.isEmpty {
            ContentUnavailableView(
                "Aucun doublon trouvé",
                systemImage: "checkmark.circle",
                description: Text("Votre photothèque ne contient pas de doublons ou similaires")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(appState.groups) { group in
                        GroupCard(group: group)
                    }
                }
                .padding()
            }
        }
    }
}

struct GroupCard: View {
    @EnvironmentObject var appState: AppState
    let group: Group

    @State private var localMembers: [GroupMember]

    init(group: Group) {
        self.group = group
        _localMembers = State(initialValue: group.members)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label(
                    group.type == .duplicate ? "Doublons" : "Similaires",
                    systemImage: group.type == .duplicate ? "rectangle.on.rectangle" : "square.grid.2x2"
                )
                .font(.headline)
                .foregroundStyle(group.type == .duplicate ? .red : .orange)

                Spacer()

                Text("\(localMembers.count) photos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Thumbnails grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(localMembers.indices, id: \.self) { index in
                    MemberThumbnail(
                        member: localMembers[index],
                        isSelected: Binding(
                            get: { localMembers[index].isSelected },
                            set: { newValue in
                                localMembers[index].isSelected = newValue
                                updateGroup()
                            }
                        )
                    )
                }
            }

            // Potential savings
            if group.potentialSavings > 0 {
                HStack {
                    Image(systemName: "internaldrive.fill")
                        .foregroundStyle(.green)
                        .font(.caption)

                    Text("Économie: \(Sweeper.formatBytes(group.potentialSavings))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    private func updateGroup() {
        if let index = appState.groups.firstIndex(where: { $0.id == group.id }) {
            appState.groups[index] = Group(
                id: group.id,
                type: group.type,
                members: localMembers,
                createdAt: group.createdAt
            )
            appState.updateSelectionStats()
        }
    }
}

struct MemberThumbnail: View {
    let member: GroupMember
    @Binding var isSelected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Placeholder thumbnail (real app would load actual image)
            Rectangle()
                .fill(.gray.gradient)
                .aspectRatio(1.0, contentMode: .fit)
                .overlay {
                    VStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))

                        Text("\(member.resolution / 1_000_000)MP")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .cornerRadius(8)

            // Selection indicator
            if member.shouldKeep {
                Label("À garder", systemImage: "checkmark.circle.fill")
                    .font(.caption2)
                    .padding(6)
                    .background(.green)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .padding(4)
            } else {
                Button(action: {
                    isSelected.toggle()
                }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .red : .white)
                        .shadow(radius: 2)
                        .padding(8)
                }
            }
        }
    }
}

#Preview {
    DuplicatesTab()
        .environmentObject({
            let state = AppState()
            state.groups = [
                Group(type: .duplicate, members: [
                    GroupMember(id: "1", fileSize: 1_000_000, resolution: 3_000_000, sharpness: 100, creationDate: Date(), shouldKeep: true, isSelected: false),
                    GroupMember(id: "2", fileSize: 500_000, resolution: 2_000_000, sharpness: 90, creationDate: Date(), shouldKeep: false, isSelected: true),
                    GroupMember(id: "3", fileSize: 800_000, resolution: 2_500_000, sharpness: 95, creationDate: Date(), shouldKeep: false, isSelected: true)
                ])
            ]
            return state
        }())
}

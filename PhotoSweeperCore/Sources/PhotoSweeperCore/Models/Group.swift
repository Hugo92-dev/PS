import Foundation

/// Group of duplicate or similar assets
public struct Group: Identifiable, Codable, Hashable {
    public let id: UUID
    public let type: GroupType
    public let members: [GroupMember]
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        type: GroupType,
        members: [GroupMember],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.members = members
        self.createdAt = createdAt
    }

    /// Best member to keep (auto-selected)
    public var bestMember: GroupMember? {
        members.first { $0.shouldKeep }
    }

    /// Members marked for deletion
    public var membersToDelete: [GroupMember] {
        members.filter { $0.isSelected && !$0.shouldKeep }
    }

    /// Total size that can be saved if selected members are deleted
    public var potentialSavings: Int64 {
        membersToDelete.reduce(0) { $0 + $1.fileSize }
    }
}

public enum GroupType: String, Codable {
    case duplicate // Hamming ≤ 8 or Vision distance ≤ d₁
    case similar   // Hamming 9-18 or Vision distance ≤ d₂
}

/// Member of a group with selection state
public struct GroupMember: Identifiable, Codable, Hashable {
    public let id: String // Asset ID
    public let fileSize: Int64
    public let resolution: Int
    public let sharpness: Double
    public let creationDate: Date?
    public var shouldKeep: Bool // Auto-selected (best quality)
    public var isSelected: Bool // User can modify

    public init(
        id: String,
        fileSize: Int64,
        resolution: Int,
        sharpness: Double,
        creationDate: Date?,
        shouldKeep: Bool,
        isSelected: Bool
    ) {
        self.id = id
        self.fileSize = fileSize
        self.resolution = resolution
        self.sharpness = sharpness
        self.creationDate = creationDate
        self.shouldKeep = shouldKeep
        self.isSelected = isSelected
    }
}

import Foundation

/// Persistent scan progress for resumable scans
public struct ScanProgress: Codable {
    public let scanID: UUID
    public let startedAt: Date
    public var lastUpdatedAt: Date
    public var cursor: String? // Last processed asset localIdentifier
    public var processedCount: Int
    public var totalCount: Int
    public var status: ScanStatus

    public init(
        scanID: UUID = UUID(),
        startedAt: Date = Date(),
        lastUpdatedAt: Date = Date(),
        cursor: String? = nil,
        processedCount: Int = 0,
        totalCount: Int = 0,
        status: ScanStatus = .pending
    ) {
        self.scanID = scanID
        self.startedAt = startedAt
        self.lastUpdatedAt = lastUpdatedAt
        self.cursor = cursor
        self.processedCount = processedCount
        self.totalCount = totalCount
        self.status = status
    }

    public var progress: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(processedCount) / Double(totalCount)
    }

    public var progressPercentage: Int {
        Int(progress * 100)
    }
}

public enum ScanStatus: String, Codable {
    case pending
    case running
    case paused
    case completed
    case failed
}

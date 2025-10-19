import Foundation

/// Heuristic label for useless photos detection
public enum HeuristicLabel: String, Codable, CaseIterable {
    case blur       // Laplacian variance < threshold
    case flat       // Low entropy (quasi-uniform background)
    case black      // Mean luminance ~0%
    case white      // Mean luminance ~100%
    case finger     // High skin tone percentage + low texture
    case burst      // Burst sequence (keep 1, rest marked)

    public var displayName: String {
        switch self {
        case .blur: return "Floue"
        case .flat: return "Fond quasi-uni"
        case .black: return "Noire"
        case .white: return "Blanche"
        case .finger: return "Doigt probable"
        case .burst: return "Rafale"
        }
    }

    public var icon: String {
        switch self {
        case .blur: return "camera.filters"
        case .flat: return "rectangle.fill"
        case .black: return "moon.fill"
        case .white: return "sun.max.fill"
        case .finger: return "hand.raised.fill"
        case .burst: return "square.stack.3d.up.fill"
        }
    }
}

/// Heuristic classification result
public struct HeuristicResult: Identifiable, Codable {
    public let id: UUID
    public let assetID: String
    public let labels: [HeuristicLabel]
    public let confidence: Double // 0.0 - 1.0
    public let reason: String // Human-readable explanation
    public var isSelected: Bool // User can deselect

    public init(
        id: UUID = UUID(),
        assetID: String,
        labels: [HeuristicLabel],
        confidence: Double,
        reason: String,
        isSelected: Bool = true
    ) {
        self.id = id
        self.assetID = assetID
        self.labels = labels
        self.confidence = confidence
        self.reason = reason
        self.isSelected = isSelected
    }
}

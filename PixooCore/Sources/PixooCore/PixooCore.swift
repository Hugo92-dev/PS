// PixooCore - Main module file
// Exports all public APIs

@_exported import struct Foundation.UUID
@_exported import struct Foundation.Date
@_exported import struct Foundation.Data
@_exported import struct Foundation.URL
@_exported import class Foundation.JSONEncoder
@_exported import class Foundation.JSONDecoder

// MARK: - Public Types
// Models
public typealias Asset = PixooCore.Asset
public typealias Feature = PixooCore.Feature
public typealias Group = PixooCore.Group
public typealias GroupMember = PixooCore.GroupMember
public typealias GroupType = PixooCore.GroupType
public typealias HeuristicLabel = PixooCore.HeuristicLabel
public typealias HeuristicResult = PixooCore.HeuristicResult
public typealias ScanProgress = PixooCore.ScanProgress
public typealias ScanStatus = PixooCore.ScanStatus
public typealias SweeperConfig = PixooCore.SweeperConfig
public typealias ColorAnalysis = PixooCore.ColorAnalysis
public typealias MediaType = PixooCore.MediaType

// Main API
public typealias Sweeper = PixooCore.Sweeper
public typealias Storage = PixooCore.Storage

// Algorithms (for advanced usage)
public typealias PHash = PixooCore.PHash
public typealias LaplacianVariance = PixooCore.LaplacianVariance
public typealias Entropy = PixooCore.Entropy
public typealias ColorAnalyzer = PixooCore.ColorAnalyzer
public typealias FeatureExtractor = PixooCore.FeatureExtractor
public typealias Clustering = PixooCore.Clustering
public typealias HeuristicClassifier = PixooCore.HeuristicClassifier

// PhotoSweeperCore - Main module file
// Exports all public APIs

@_exported import struct Foundation.UUID
@_exported import struct Foundation.Date
@_exported import struct Foundation.Data
@_exported import struct Foundation.URL
@_exported import class Foundation.JSONEncoder
@_exported import class Foundation.JSONDecoder

// MARK: - Public Types
// Models
public typealias Asset = PhotoSweeperCore.Asset
public typealias Feature = PhotoSweeperCore.Feature
public typealias Group = PhotoSweeperCore.Group
public typealias GroupMember = PhotoSweeperCore.GroupMember
public typealias GroupType = PhotoSweeperCore.GroupType
public typealias HeuristicLabel = PhotoSweeperCore.HeuristicLabel
public typealias HeuristicResult = PhotoSweeperCore.HeuristicResult
public typealias ScanProgress = PhotoSweeperCore.ScanProgress
public typealias ScanStatus = PhotoSweeperCore.ScanStatus
public typealias SweeperConfig = PhotoSweeperCore.SweeperConfig
public typealias ColorAnalysis = PhotoSweeperCore.ColorAnalysis
public typealias MediaType = PhotoSweeperCore.MediaType

// Main API
public typealias Sweeper = PhotoSweeperCore.Sweeper
public typealias Storage = PhotoSweeperCore.Storage

// Algorithms (for advanced usage)
public typealias PHash = PhotoSweeperCore.PHash
public typealias LaplacianVariance = PhotoSweeperCore.LaplacianVariance
public typealias Entropy = PhotoSweeperCore.Entropy
public typealias ColorAnalyzer = PhotoSweeperCore.ColorAnalyzer
public typealias FeatureExtractor = PhotoSweeperCore.FeatureExtractor
public typealias Clustering = PhotoSweeperCore.Clustering
public typealias HeuristicClassifier = PhotoSweeperCore.HeuristicClassifier

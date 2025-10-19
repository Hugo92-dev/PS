import Foundation

/// Simple JSON-based persistent storage
public class Storage {
    private let fileManager = FileManager.default
    private let baseURL: URL

    public init(baseURL: URL? = nil) {
        if let url = baseURL {
            self.baseURL = url
        } else {
            // Default to Application Support
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.baseURL = appSupport.appendingPathComponent("PhotoSweeperCore", isDirectory: true)
        }

        // Create directory if needed
        try? fileManager.createDirectory(at: self.baseURL, withIntermediateDirectories: true)
    }

    // MARK: - Features

    public func saveFeatures(_ features: [Feature]) throws {
        let url = baseURL.appendingPathComponent("features.json")
        let data = try JSONEncoder().encode(features)
        try data.write(to: url)
    }

    public func loadFeatures() throws -> [Feature] {
        let url = baseURL.appendingPathComponent("features.json")
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Feature].self, from: data)
    }

    // MARK: - Groups

    public func saveGroups(_ groups: [Group]) throws {
        let url = baseURL.appendingPathComponent("groups.json")
        let data = try JSONEncoder().encode(groups)
        try data.write(to: url)
    }

    public func loadGroups() throws -> [Group] {
        let url = baseURL.appendingPathComponent("groups.json")
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Group].self, from: data)
    }

    // MARK: - Heuristics

    public func saveHeuristics(_ results: [HeuristicResult]) throws {
        let url = baseURL.appendingPathComponent("heuristics.json")
        let data = try JSONEncoder().encode(results)
        try data.write(to: url)
    }

    public func loadHeuristics() throws -> [HeuristicResult] {
        let url = baseURL.appendingPathComponent("heuristics.json")
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([HeuristicResult].self, from: data)
    }

    // MARK: - Scan Progress

    public func saveScanProgress(_ progress: ScanProgress) throws {
        let url = baseURL.appendingPathComponent("scan_progress.json")
        let data = try JSONEncoder().encode(progress)
        try data.write(to: url)
    }

    public func loadScanProgress() throws -> ScanProgress? {
        let url = baseURL.appendingPathComponent("scan_progress.json")
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ScanProgress.self, from: data)
    }

    public func deleteScanProgress() throws {
        let url = baseURL.appendingPathComponent("scan_progress.json")
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - Clear All

    public func clearAll() throws {
        let files = ["features.json", "groups.json", "heuristics.json", "scan_progress.json"]
        for file in files {
            let url = baseURL.appendingPathComponent(file)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
    }
}

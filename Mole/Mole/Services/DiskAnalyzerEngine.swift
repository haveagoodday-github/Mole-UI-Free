//
//  DiskAnalyzerEngine.swift
//  Mole
//

import AppKit
import Combine
import Foundation

public struct DiskAnalysisCacheEntry: Codable {
    public let result: DiskAnalysisResult
    public let timestamp: Date

    public init(result: DiskAnalysisResult, timestamp: Date = Date()) {
        self.result = result
        self.timestamp = timestamp
    }
}

@MainActor
public final class DiskAnalyzerEngine: ObservableObject {
    public static let shared = DiskAnalyzerEngine()

    @Published public var currentPath: String = NSHomeDirectory()
    @Published public var currentResult: DiskAnalysisResult?
    @Published public var isAnalyzing: Bool = false
    @Published public var historyPaths: [String] = []
    @Published public var isFromCache: Bool = false
    @Published public var cacheDate: Date?

    private var cache: [String: DiskAnalysisCacheEntry] = [:]
    private let cacheTTL: TimeInterval = 600 // 10 minutes cache validity

    private let runner = MoleProcessRunner.shared
    private let fileManager = FileManager.default

    private var diskCacheURL: URL? {
        guard let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let moleDir = cachesDir.appendingPathComponent("Mole", isDirectory: true)
        try? fileManager.createDirectory(at: moleDir, withIntermediateDirectories: true)
        return moleDir.appendingPathComponent("disk_analysis_cache.json")
    }

    private init() {
        loadCacheFromDisk()
    }

    private var currentAnalysisTask: Task<Void, Never>?

    /// Cancel the current ongoing analysis task immediately
    public func cancelAnalysis() {
        currentAnalysisTask?.cancel()
        currentAnalysisTask = nil
        isAnalyzing = false
    }

    /// Analyze a specific path with smart cache lookup, automatically canceling previous in-flight scans
    public func analyze(path: String, forceRefresh: Bool = false) async {
        // Cancel any previous analysis in progress
        currentAnalysisTask?.cancel()

        let task = Task { [weak self] in
            guard let self = self else { return }
            await self.performAnalysis(path: path, forceRefresh: forceRefresh)
        }
        currentAnalysisTask = task
        await task.value
    }

    private func performAnalysis(path: String, forceRefresh: Bool) async {
        let standardizedPath = (path as NSString).standardizingPath
        currentPath = standardizedPath

        if Task.isCancelled { return }

        // 1. Check in-memory & disk cache if not forcing refresh
        if !forceRefresh, let cached = cache[standardizedPath] {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age < cacheTTL {
                self.currentResult = cached.result
                self.isFromCache = true
                self.cacheDate = cached.timestamp
                self.isAnalyzing = false
                return
            }
        }

        // 2. Perform scan via analyze-go in background
        isAnalyzing = true

        guard let analyzeBin = runner.resolveExecutable(named: "analyze-go") else {
            isAnalyzing = false
            return
        }

        if Task.isCancelled {
            isAnalyzing = false
            return
        }

        let cmd = "\"\(analyzeBin)\" --json \"\(standardizedPath)\""
        let result = await runner.runShellCommand(cmd, silent: true)

        if Task.isCancelled {
            isAnalyzing = false
            return
        }

        if result.exitCode == 0, let data = result.output.data(using: .utf8) {
            do {
                let parsed = try JSONDecoder().decode(DiskAnalysisResult.self, from: data)
                if !Task.isCancelled {
                    self.currentResult = parsed
                    self.isFromCache = false
                    self.cacheDate = Date()

                    // Save to cache
                    let entry = DiskAnalysisCacheEntry(result: parsed, timestamp: Date())
                    self.cache[standardizedPath] = entry
                    saveCacheToDisk()
                }
            } catch {
                print("Failed to decode disk analysis: \(error)")
            }
        }

        isAnalyzing = false
    }

    /// Drill down into a subdirectory (reuses cache if available)
    public func navigateTo(subpath: String) async {
        historyPaths.append(currentPath)
        await analyze(path: subpath, forceRefresh: false)
    }

    /// Go back to parent directory (reuses cache if available)
    public func goBack() async {
        guard let prev = historyPaths.popLast() else {
            let parent = (currentPath as NSString).deletingLastPathComponent
            if !parent.isEmpty && parent != currentPath {
                await analyze(path: parent, forceRefresh: false)
            }
            return
        }
        await analyze(path: prev, forceRefresh: false)
    }

    /// Invalidate cache for a path and its parents
    public func invalidateCache(for path: String) {
        let standardized = (path as NSString).standardizingPath
        cache.removeValue(forKey: standardized)

        // Invalidate parent dirs as their total size changed
        var p = (standardized as NSString).deletingLastPathComponent
        while !p.isEmpty && p != "/" {
            cache.removeValue(forKey: p)
            p = (p as NSString).deletingLastPathComponent
        }
        cache.removeValue(forKey: "/")

        saveCacheToDisk()
    }

    /// Clear all caches
    public func clearAllCache() {
        cache.removeAll()
        if let url = diskCacheURL {
            try? fileManager.removeItem(at: url)
        }
        isFromCache = false
        cacheDate = nil
    }

    /// Reveal item in Finder
    public func revealInFinder(path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }

    /// Move item to Trash and refresh parent
    public func moveToTrash(path: String) async {
        do {
            try fileManager.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: nil)
            runner.appendLog("🗑️ 已将项目移至废纸篓: \(path)")
            invalidateCache(for: currentPath)
            await analyze(path: currentPath, forceRefresh: true)
        } catch {
            runner.appendLog("❌ 无法移至废纸篓: \(error.localizedDescription)")
        }
    }

    // MARK: - Persistence
    private func loadCacheFromDisk() {
        guard let url = diskCacheURL, let data = try? Data(contentsOf: url) else { return }
        do {
            let loaded = try JSONDecoder().decode([String: DiskAnalysisCacheEntry].self, from: data)
            // Filter expired entries
            let now = Date()
            self.cache = loaded.filter { now.timeIntervalSince($0.value.timestamp) < cacheTTL }
        } catch {
            print("Failed to load disk analysis cache: \(error)")
        }
    }

    private func saveCacheToDisk() {
        guard let url = diskCacheURL else { return }
        let currentCache = self.cache
        Task.detached(priority: .background) {
            if let data = try? JSONEncoder().encode(currentCache) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    public var formattedCacheDate: String {
        guard let date = cacheDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

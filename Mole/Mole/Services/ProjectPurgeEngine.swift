//
//  ProjectPurgeEngine.swift
//  Mole
//

import AppKit
import Combine
import Foundation

@MainActor
public final class ProjectPurgeEngine: ObservableObject {
    public static let shared = ProjectPurgeEngine()

    @Published public var scanDirectory: String = "\(NSHomeDirectory())/Developer"
    @Published public var artifacts: [ProjectArtifactItem] = []
    @Published public var installers: [InstallerItem] = []
    @Published public var isScanning: Bool = false
    @Published public var isPurging: Bool = false
    @Published public var statusMessage: String = ""

    private let runner = MoleProcessRunner.shared
    private let fileManager = FileManager.default

    private init() {
        if !fileManager.fileExists(atPath: scanDirectory) {
            scanDirectory = NSHomeDirectory()
        }
    }

    public var totalArtifactBytes: Int64 {
        artifacts.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeInBytes }
    }

    public var totalInstallerBytes: Int64 {
        installers.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeInBytes }
    }

    private var currentScanTask: Task<Void, Never>?

    /// Cancel current ongoing scan immediately
    public func cancelScan() {
        currentScanTask?.cancel()
        currentScanTask = nil
        isScanning = false
        statusMessage = "扫描已取消".localized
    }

    /// Scan directory for developer project build artifacts
    public func scanProjects(in rootDirectory: String) async {
        currentScanTask?.cancel()

        let task = Task { [weak self] in
            guard let self = self else { return }
            await self.performScanProjects(in: rootDirectory)
        }
        currentScanTask = task
        await task.value
    }

    private func performScanProjects(in rootDirectory: String) async {
        isScanning = true
        scanDirectory = rootDirectory
        statusMessage = "正在扫描工程构建产物...".localized
        artifacts.removeAll()

        let targetDirNames: [String: ArtifactCategory] = [
            "node_modules": .nodeModules,
            "DerivedData": .xcode,
            ".build": .xcode,
            "Pods": .cocoaPods,
            "target": .rust,
            ".gradle": .gradle,
            ".venv": .pythonVenv,
            "venv": .pythonVenv,
            ".next": .webBuild,
            "dist": .webBuild
        ]

        var foundItems: [ProjectArtifactItem] = []

        await Task.detached {
            let rootURL = URL(fileURLWithPath: rootDirectory)
            guard let enumerator = FileManager.default.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
                options: [.skipsPackageDescendants],
                errorHandler: nil
            ) else { return }

            var visitedCount = 0
            for case let itemURL as URL in enumerator {
                if Task.isCancelled { break }
                visitedCount += 1
                if visitedCount > 30000 { break } // safety limit

                let lastComp = itemURL.lastPathComponent
                if let category = targetDirNames[lastComp] {
                    // Skip descending into this target directory
                    enumerator.skipDescendants()

                    let path = itemURL.path
                    let parentName = itemURL.deletingLastPathComponent().lastPathComponent
                    let size = ProjectPurgeEngine.calculateDirSize(path: path)
                    if Task.isCancelled { break }

                    if size > 1024 * 1024 { // at least 1MB
                        foundItems.append(ProjectArtifactItem(
                            projectName: parentName,
                            artifactPath: path,
                            category: category,
                            sizeInBytes: size
                        ))
                    }
                }
            }
        }.value

        if !Task.isCancelled {
            self.artifacts = foundItems.sorted { $0.sizeInBytes > $1.sizeInBytes }
            self.statusMessage = "扫描完成，发现 %lld 个构建缓存项目".localized(with: Int64(artifacts.count))
        }
        self.isScanning = false
    }

    /// Scan for installer files (.dmg, .pkg, .iso, .zip)
    public func scanInstallers() async {
        currentScanTask?.cancel()

        let task = Task { [weak self] in
            guard let self = self else { return }
            await self.performScanInstallers()
        }
        currentScanTask = task
        await task.value
    }

    private func performScanInstallers() async {
        isScanning = true
        statusMessage = "正在排查下载目录与桌面残留安装包...".localized
        installers.removeAll()

        let targetDirs = [
            "\(NSHomeDirectory())/Downloads",
            "\(NSHomeDirectory())/Desktop"
        ]

        let extensions: Set<String> = ["dmg", "pkg", "mpkg", "iso"]
        var found: [InstallerItem] = []

        await Task.detached {
            for dir in targetDirs {
                if Task.isCancelled { break }
                guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
                for file in files {
                    if Task.isCancelled { break }
                    let ext = (file as NSString).pathExtension.lowercased()
                    if extensions.contains(ext) {
                        let fullPath = (dir as NSString).appendingPathComponent(file)
                        let attrs = try? FileManager.default.attributesOfItem(atPath: fullPath)
                        let size = (attrs?[.size] as? Int64) ?? 0
                        let modDate = attrs?[.modificationDate] as? Date

                        found.append(InstallerItem(
                            name: file,
                            path: fullPath,
                            sizeInBytes: size,
                            modificationDate: modDate
                        ))
                    }
                }
            }
        }.value

        if !Task.isCancelled {
            self.installers = found.sorted { $0.sizeInBytes > $1.sizeInBytes }
            self.statusMessage = "发现 %lld 个安装包文件".localized(with: Int64(installers.count))
        }
        self.isScanning = false
    }

    /// Purge selected build artifacts
    public func purgeSelectedArtifacts() async {
        isPurging = true
        let selected = artifacts.filter { $0.isSelected }

        for item in selected {
            runner.appendLog("🧹 清理项目构建缓存: \(item.projectName) -> \(item.artifactPath)")
            try? fileManager.removeItem(atPath: item.artifactPath)
        }

        artifacts.removeAll { $0.isSelected }
        isPurging = false
        statusMessage = "已清理选中的构建产物".localized
    }

    /// Purge selected installers
    public func purgeSelectedInstallers() async {
        isPurging = true
        let selected = installers.filter { $0.isSelected }

        for item in selected {
            runner.appendLog("🗑️ 移除安装包: \(item.path)")
            try? fileManager.removeItem(atPath: item.path)
        }

        installers.removeAll { $0.isSelected }
        isPurging = false
        statusMessage = "已移除选中的安装包".localized
    }

    nonisolated private static func calculateDirSize(path: String) -> Int64 {
        let url = URL(fileURLWithPath: path)
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else { return 0 }

        var total: Int64 = 0
        var count = 0
        for case let fileURL as URL in enumerator {
            count += 1
            if count % 200 == 0 && Task.isCancelled { break }
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey]) {
                total += Int64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0)
            }
        }
        return total
    }
}

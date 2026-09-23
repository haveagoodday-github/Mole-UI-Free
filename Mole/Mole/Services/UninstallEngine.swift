//
//  UninstallEngine.swift
//  Mole
//

import AppKit
import Combine
import Foundation

@MainActor
public final class UninstallEngine: ObservableObject {
    public static let shared = UninstallEngine()

    @Published public var installedApps: [InstalledApp] = []
    @Published public var isLoading: Bool = false
    @Published public var selectedApp: InstalledApp?
    @Published public var isScanningRemnants: Bool = false
    @Published public var searchText: String = ""

    private let runner = MoleProcessRunner.shared
    private let fileManager = FileManager.default

    private init() {}

    public var filteredApps: [InstalledApp] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return installedApps
        }
        return installedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.bundleIdentifier?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var currentScanTask: Task<Void, Never>?

    /// Cancel any ongoing app scan immediately
    public func cancelScan() {
        currentScanTask?.cancel()
        currentScanTask = nil
        isLoading = false
    }

    /// Scan installed applications from /Applications and ~/Applications
    public func scanInstalledApps() async {
        currentScanTask?.cancel()

        let task = Task { [weak self] in
            guard let self = self else { return }
            await self.performScanInstalledApps()
        }
        currentScanTask = task
        await task.value
    }

    private func performScanInstalledApps() async {
        isLoading = true
        var apps: [InstalledApp] = []

        let appDirs = [
            "/Applications",
            "\(NSHomeDirectory())/Applications"
        ]

        await Task.detached {
            for dir in appDirs {
                if Task.isCancelled { break }
                guard let items = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
                for item in items where item.hasSuffix(".app") {
                    if Task.isCancelled { break }
                    let appPath = (dir as NSString).appendingPathComponent(item)
                    let bundleURL = URL(fileURLWithPath: appPath)
                    guard let bundle = Bundle(url: bundleURL) else { continue }

                    let info = bundle.infoDictionary
                    let name = (info?["CFBundleDisplayName"] as? String) ??
                               (info?["CFBundleName"] as? String) ??
                               (item as NSString).deletingPathExtension
                    let bundleId = bundle.bundleIdentifier
                    let version = info?["CFBundleShortVersionString"] as? String

                    // App size
                    let size = UninstallEngine.calculateAppSize(path: appPath)
                    if Task.isCancelled { break }

                    // Last used date
                    let lastUsed = UninstallEngine.getLastUsedDate(path: appPath)

                    let app = InstalledApp(
                        name: name,
                        bundleIdentifier: bundleId,
                        version: version,
                        path: appPath,
                        appSizeInBytes: size,
                        lastUsedDate: lastUsed
                    )
                    apps.append(app)
                }
            }
        }.value

        if !Task.isCancelled {
            // Sort by size descending by default
            self.installedApps = apps.sorted { $0.appSizeInBytes > $1.appSizeInBytes }
        }
        self.isLoading = false
    }

    /// Deep scan remnants for a specific installed app
    public func scanRemnants(for app: InstalledApp) async {
        isScanningRemnants = true
        var remnants: [AppRemnantItem] = []

        let home = NSHomeDirectory()
        let name = app.name
        let bundleId = app.bundleIdentifier

        let searchLocations: [(RemnantType, [String])] = [
            (.appSupport, [
                "\(home)/Library/Application Support/\(name)",
                bundleId.map { "\(home)/Library/Application Support/\($0)" }
            ].compactMap { $0 }),
            (.caches, [
                bundleId.map { "\(home)/Library/Caches/\($0)" },
                "\(home)/Library/Caches/\(name)"
            ].compactMap { $0 }),
            (.preferences, [
                bundleId.map { "\(home)/Library/Preferences/\($0).plist" }
            ].compactMap { $0 }),
            (.containers, [
                bundleId.map { "\(home)/Library/Containers/\($0)" }
            ].compactMap { $0 }),
            (.savedState, [
                bundleId.map { "\(home)/Library/Saved Application State/\($0).savedState" }
            ].compactMap { $0 }),
            (.logs, [
                "\(home)/Library/Logs/\(name)",
                bundleId.map { "\(home)/Library/Logs/\($0)" }
            ].compactMap { $0 }),
            (.webkit, [
                bundleId.map { "\(home)/Library/WebKit/\($0)" }
            ].compactMap { $0 }),
            (.launchAgents, [
                bundleId.map { "\(home)/Library/LaunchAgents/\($0).plist" },
                bundleId.map { "/Library/LaunchAgents/\($0).plist" }
            ].compactMap { $0 })
        ]

        await Task.detached {
            for (type, paths) in searchLocations {
                for path in paths {
                    if FileManager.default.fileExists(atPath: path) {
                        let size = UninstallEngine.calculateAppSize(path: path)
                        remnants.append(AppRemnantItem(path: path, type: type, sizeInBytes: size))
                    }
                }
            }
        }.value

        if let idx = installedApps.firstIndex(where: { $0.id == app.id }) {
            installedApps[idx].remnants = remnants
            self.selectedApp = installedApps[idx]
        }
        isScanningRemnants = false
    }

    /// Uninstall the selected application and its remnants
    public func uninstallApp(_ app: InstalledApp, removeRemnants: Bool = true) async {
        runner.appendLog("🗑️ 正在卸载应用: \(app.name) (\(app.path))")

        // 1. Remove app bundle
        try? fileManager.removeItem(atPath: app.path)

        // 2. Remove selected remnants
        if removeRemnants {
            for remnant in app.remnants where remnant.isSelected {
                runner.appendLog("  ↳ 清理残留: \(remnant.path)")
                try? fileManager.removeItem(atPath: remnant.path)
            }
        }

        installedApps.removeAll { $0.id == app.id }
        if selectedApp?.id == app.id {
            selectedApp = nil
        }
    }

    nonisolated private static func calculateAppSize(path: String) -> Int64 {
        let url = URL(fileURLWithPath: path)
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
            return (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int64) ?? 0
        }

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey],
            options: [],
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

    nonisolated private static func getLastUsedDate(path: String) -> Date? {
        let attrs = try? FileManager.default.attributesOfItem(atPath: path)
        return attrs?[.modificationDate] as? Date
    }
}

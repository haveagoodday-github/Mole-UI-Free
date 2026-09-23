//
//  CleanEngine.swift
//  Mole
//

import Combine
import Foundation

@MainActor
public final class CleanEngine: ObservableObject {
    public static let shared = CleanEngine()

    @Published public var items: [CleanItem] = []
    @Published public var isScanning: Bool = false
    @Published public var isCleaning: Bool = false
    @Published public var scanProgress: Double = 0.0
    @Published public var cleanProgress: Double = 0.0
    @Published public var lastCleanedBytes: Int64 = 0
    @Published public var lastCleanedDate: Date?

    private let runner = MoleProcessRunner.shared
    private let fileManager = FileManager.default

    private init() {}

    public var totalSelectedBytes: Int64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeInBytes }
    }

    public var totalReclaimableBytes: Int64 {
        items.reduce(0) { $0 + $1.sizeInBytes }
    }

    public var formattedTotalSelected: String {
        ByteCountFormatter.string(fromByteCount: totalSelectedBytes, countStyle: .file)
    }

    public var formattedTotalReclaimable: String {
        ByteCountFormatter.string(fromByteCount: totalReclaimableBytes, countStyle: .file)
    }

    public func items(for category: CleanCategoryType) -> [CleanItem] {
        items.filter { $0.category == category }
    }

    public func totalBytes(for category: CleanCategoryType) -> Int64 {
        items(for: category).reduce(0) { $0 + $1.sizeInBytes }
    }

    public func selectAll(_ select: Bool) {
        for index in items.indices {
            items[index].isSelected = select
        }
    }

    public func toggleCategory(_ category: CleanCategoryType, isSelected: Bool) {
        for index in items.indices where items[index].category == category {
            items[index].isSelected = isSelected
        }
    }

    private var currentScanTask: Task<Void, Never>?

    /// Cancel the current scan immediately
    public func cancelScan() {
        currentScanTask?.cancel()
        currentScanTask = nil
        isScanning = false
    }

    /// Perform fast native scan across all standard Mole cleanup paths
    public func scanAll() async {
        currentScanTask?.cancel()

        let task = Task { [weak self] in
            guard let self = self else { return }
            await self.performScan()
        }
        currentScanTask = task
        await task.value
    }

    private func performScan() async {
        isScanning = true
        scanProgress = 0.0
        items.removeAll()

        let home = NSHomeDirectory()
        let scanTargets: [(name: String, cat: CleanCategoryType, path: String, desc: String)] = [
            // User Caches
            ("通用用户缓存", .userCaches, "\(home)/Library/Caches", "macOS 用户应用程序缓存目录"),
            ("Safari 网页缓存", .userCaches, "\(home)/Library/Caches/com.apple.Safari", "Safari 浏览临时数据与缩略图"),
            ("Google Chrome 缓存", .userCaches, "\(home)/Library/Caches/Google/Chrome", "Chrome 浏览器网络资源与本地缓存"),
            ("Microsoft Edge 缓存", .userCaches, "\(home)/Library/Caches/Microsoft Edge", "Edge 浏览器缓存"),
            ("微信缓存与临时文件", .appCaches, "\(home)/Library/Caches/com.tencent.xinWeChat", "微信本地缩略图与网络资源缓存"),
            ("QQ 缓存文件", .appCaches, "\(home)/Library/Caches/com.tencent.qq", "QQ 聊天临时文件与缓存"),
            ("网易云音乐/流媒体缓存", .appCaches, "\(home)/Library/Caches/com.netease.163music", "音频本地缓存与封面图"),

            // Developer Caches
            ("Xcode DerivedData", .devCaches, "\(home)/Library/Developer/Xcode/DerivedData", "Xcode 历史编译产物、索引与模块缓存"),
            ("Xcode Archives (旧归档)", .devCaches, "\(home)/Library/Developer/Xcode/Archives", "旧版本的构建签名产物包"),
            ("iOS 设备支持与模拟器缓存", .devCaches, "\(home)/Library/Developer/Xcode/iOS DeviceSupport", "已连接调试设备符号文件"),
            ("CocoaPods 依赖下载缓存", .devCaches, "\(home)/.cocoapods/cache", "CocoaPods 已下载的库文件镜像"),
            ("Cargo 依赖包下载缓存", .devCaches, "\(home)/.cargo/registry/cache", "Rust Crates 下载压缩包"),
            ("Gradle 构建与依赖缓存", .devCaches, "\(home)/.gradle/caches", "Gradle 构建依赖与临时守护文件"),
            ("npm 缓存 (_cacache)", .devCaches, "\(home)/.npm/_cacache", "Node.js npm 全局下载包缓存"),
            ("Homebrew 下载缓存", .devCaches, "\(home)/Library/Caches/Homebrew", "已下载但未清理的 Homebrew 安装包"),

            // System Logs
            ("用户应用诊断与崩溃日志", .systemLogs, "\(home)/Library/Logs", "应用程序运行与崩溃记录"),
            ("系统诊断报告", .systemLogs, "\(home)/Library/Logs/DiagnosticReports", "系统崩溃转储与堆栈快照"),
            ("ASL 系统日志缓存", .systemLogs, "/private/var/log/asl", "macOS 系统底层服务历史日志"),

            // App Leftovers
            ("已删除软件孤儿配置", .appLeftovers, "\(home)/Library/Application Support/CrashReporter", "历史崩溃报告器冗余记录"),

            // Trash
            ("当前用户废纸篓", .trash, "\(home)/.Trash", "等待清空的废纸篓项目")
        ]

        let totalCount = Double(scanTargets.count)

        for (index, target) in scanTargets.enumerated() {
            if Task.isCancelled { break }

            let path = target.path
            if fileManager.fileExists(atPath: path) {
                let size = await calculateDirectorySize(atPath: path)
                if Task.isCancelled { break }

                if size > 0 {
                    let item = CleanItem(
                        name: target.name,
                        category: target.cat,
                        path: path,
                        sizeInBytes: size,
                        isSelected: target.cat != .trash, // trash unselected by default for safety
                        itemDescription: target.desc
                    )
                    // Stream item immediately so UI is responsive
                    self.items.append(item)
                }
            }
            scanProgress = Double(index + 1) / totalCount
        }

        self.isScanning = false
    }

    /// Perform actual cleanup on selected items
    public func performClean() async {
        isCleaning = true
        cleanProgress = 0.0

        let selected = items.filter { $0.isSelected }
        guard !selected.isEmpty else {
            isCleaning = false
            return
        }

        var cleanedTotal: Int64 = 0
        let count = Double(selected.count)

        for (idx, item) in selected.enumerated() {
            runner.appendLog("🧹 正在清理: \(item.name) (\(item.formattedSize))")

            // Safe cleaning: clear directory contents or safe removal
            if item.category == .trash {
                await emptyTrash(path: item.path)
            } else if item.path.hasSuffix("DerivedData") || item.path.hasSuffix("Caches") || item.path.hasSuffix("Logs") {
                await emptyDirectoryContents(atPath: item.path)
            } else {
                await removeDirectory(atPath: item.path)
            }

            cleanedTotal += item.sizeInBytes
            cleanProgress = Double(idx + 1) / count
        }

        self.lastCleanedBytes = cleanedTotal
        self.lastCleanedDate = Date()
        self.isCleaning = false

        // Re-scan to update state
        await scanAll()
    }

    private func calculateDirectorySize(atPath path: String) async -> Int64 {
        await Task.detached {
            let url = URL(fileURLWithPath: path)
            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey],
                options: [.skipsHiddenFiles],
                errorHandler: nil
            ) else {
                return 0
            }

            var totalSize: Int64 = 0
            var count = 0
            for case let fileURL as URL in enumerator {
                count += 1
                if count % 200 == 0 && Task.isCancelled { break }
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey]) {
                    totalSize += Int64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0)
                }
            }
            return totalSize
        }.value
    }

    private func emptyDirectoryContents(atPath path: String) async {
        await Task.detached {
            guard let entries = try? FileManager.default.contentsOfDirectory(atPath: path) else { return }
            for entry in entries {
                let subPath = (path as NSString).appendingPathComponent(entry)
                try? FileManager.default.removeItem(atPath: subPath)
            }
        }.value
    }

    private func removeDirectory(atPath path: String) async {
        await Task.detached {
            try? FileManager.default.removeItem(atPath: path)
        }.value
    }

    private func emptyTrash(path: String) async {
        await emptyDirectoryContents(atPath: path)
    }
}

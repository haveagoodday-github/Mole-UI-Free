//
//  AnalyzeView.swift
//  Mole
//

import AppKit
import SwiftUI

public struct AnalyzeView: View {
    @ObservedObject var engine = DiskAnalyzerEngine.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Path & Controls Bar
            pathControlsBar

            Divider()

            // Quick Shortcut Chips
            quickShortcutsBar

            Divider()

            // Content Area
            if let result = engine.currentResult {
                VStack(spacing: 0) {
                    if engine.isAnalyzing {
                        analyzingBanner
                        Divider()
                    }
                    diskEntriesList(result: result)
                }
            } else if engine.isAnalyzing {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.2)
                    Text("Mole 磁盘分析引擎正在深度扫描目录层级与体积...".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(engine.currentPath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary.opacity(0.8))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button(role: .cancel, action: {
                        engine.cancelAnalysis()
                    }) {
                        Label("取消分析".localized, systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary.opacity(0.4))
                    Text("准备分析磁盘使用情况".localized)
                        .font(.headline)
                    Button("开始分析用户主目录".localized) {
                        Task {
                            await engine.analyze(path: NSHomeDirectory())
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
        .task {
            if engine.currentResult == nil && !engine.isAnalyzing {
                await engine.analyze(path: engine.currentPath, forceRefresh: false)
            }
        }
    }

    // MARK: - In-flight Analysis Banner
    private var analyzingBanner: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: 16, height: 16)
            Text("正在深度分析: %@...".localized(with: engine.currentPath))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Button(action: {
                engine.cancelAnalysis()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                    Text("取消分析".localized)
                }
                .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.08))
    }

    // MARK: - Path Controls Bar
    private var pathControlsBar: some View {
        HStack(spacing: 10) {
            Button(action: {
                Task {
                    await engine.goBack()
                }
            }) {
                Image(systemName: "chevron.left")
            }
            .disabled(engine.historyPaths.isEmpty && (engine.currentPath == NSHomeDirectory() || engine.currentPath == "/"))

            HStack {
                Image(systemName: "folder")
                    .foregroundStyle(.tint)
                Text(engine.currentPath)
                    .font(.caption.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))

            Spacer()

            Button(action: { pickFolder() }) {
                Label("选择目录".localized, systemImage: "folder.badge.plus")
            }

            if engine.isAnalyzing {
                Button(action: {
                    engine.cancelAnalysis()
                }) {
                    Label("取消分析".localized, systemImage: "xmark.circle.fill")
                }
                .tint(.red)
                .help("停止当前分析任务".localized)
            } else {
                Button(action: {
                    Task {
                        await engine.analyze(path: engine.currentPath, forceRefresh: true)
                    }
                }) {
                    Label("强制重新扫描".localized, systemImage: "arrow.clockwise")
                }
                .help("忽略缓存并重新深度扫描当前目录".localized)
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Quick Shortcuts Bar
    private var quickShortcutsBar: some View {
        HStack(spacing: 8) {
            Text("快捷位置:".localized)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button("用户主目录 (~)".localized) {
                Task { await engine.analyze(path: NSHomeDirectory(), forceRefresh: false) }
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)

            Button("应用程序 (/Applications)".localized) {
                Task { await engine.analyze(path: "/Applications", forceRefresh: false) }
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)

            Button("系统临时目录 (/private/tmp)".localized) {
                Task { await engine.analyze(path: "/private/tmp", forceRefresh: false) }
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)

            Spacer()

            if engine.isFromCache {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.orange)
                        .font(.caption2)
                    Text("极速缓存 (%@)".localized(with: engine.formattedCacheDate))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.orange.opacity(0.12)))
            }

            if let result = engine.currentResult {
                Text("总占用: %@".localized(with: ByteCountFormatter.string(fromByteCount: result.totalSize, countStyle: .file)))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.tint)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Disk Entries List
    private func diskEntriesList(result: DiskAnalysisResult) -> some View {
        let maxEntrySize = Double(result.entries.map(\.size).max() ?? 1)

        return List(result.entries) { entry in
            HStack(spacing: 12) {
                Image(systemName: entry.isDir ? "folder.fill" : "doc.fill")
                    .foregroundStyle(entry.isDir ? Color.blue : Color.secondary)
                    .font(.title3)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.name)
                            .font(.subheadline.weight(.medium))
                        if entry.cleanable == true {
                            Text("建议清理".localized)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.orange.opacity(0.15)))
                                .foregroundStyle(.orange)
                        }
                    }

                    // Relative Percentage Bar
                    let ratio = maxEntrySize > 0 ? (Double(entry.size) / maxEntrySize) : 0.0
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.06))
                                .frame(height: 5)
                            Capsule()
                                .fill(entry.size > 1024 * 1024 * 1024 ? Color.red.opacity(0.8) : Color.blue.opacity(0.7))
                                .frame(width: max(geo.size.width * CGFloat(ratio), 4), height: 5)
                        }
                    }
                    .frame(height: 5)
                }

                Spacer()

                Text(entry.formattedSize)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .frame(width: 80, alignment: .trailing)

                if entry.isDir {
                    Button(action: {
                        Task {
                            await engine.navigateTo(subpath: entry.path)
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
            .contextMenu {
                if entry.isDir {
                    Button("进入此文件夹".localized) {
                        Task { await engine.navigateTo(subpath: entry.path) }
                    }
                }
                Button("在访达中显示".localized) {
                    engine.revealInFinder(path: entry.path)
                }
                Divider()
                Button("移至废纸篓".localized, role: .destructive) {
                    Task { await engine.moveToTrash(path: entry.path) }
                }
            }
        }
        .listStyle(.inset)
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await engine.analyze(path: url.path)
            }
        }
    }
}

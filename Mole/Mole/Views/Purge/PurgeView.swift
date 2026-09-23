//
//  PurgeView.swift
//  Mole
//

import AppKit
import SwiftUI

public struct PurgeView: View {
    @ObservedObject var engine = ProjectPurgeEngine.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            Divider()

            // Directory Selection Bar
            directoryBar

            Divider()

            // Main List
            if !engine.artifacts.isEmpty {
                VStack(spacing: 0) {
                    if engine.isScanning {
                        scanningBanner
                        Divider()
                    }
                    artifactsList
                }
            } else if engine.isScanning {
                VStack(spacing: 14) {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.2)
                    Text(engine.statusMessage.localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button(role: .cancel, action: {
                        engine.cancelScan()
                    }) {
                        Label("取消扫描".localized, systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary.opacity(0.4))
                    Text("未发现冗余构建缓存".localized)
                        .font(.headline)
                    Text("点击上方“开始扫描”以检索指定开发工程目录下的 node_modules、DerivedData、Pods、target 等构建产物".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    Spacer()
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
    }

    // MARK: - Scanning Banner
    private var scanningBanner: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: 16, height: 16)
            Text(engine.statusMessage.localized)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Button(action: {
                engine.cancelScan()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                    Text("取消扫描".localized)
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

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("开发者工程构建清理".localized)
                    .font(.title2.weight(.bold))
                HStack(spacing: 6) {
                    Text("可回收空间:".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(ByteCountFormatter.string(fromByteCount: engine.totalArtifactBytes, countStyle: .file))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tint)
                }
            }

            Spacer()

            if engine.isScanning {
                Button(action: {
                    engine.cancelScan()
                }) {
                    Label("取消扫描".localized, systemImage: "xmark.circle.fill")
                }
                .tint(.red)
            } else {
                Button(action: {
                    Task {
                        await engine.scanProjects(in: engine.scanDirectory)
                    }
                }) {
                    Label("扫描工程".localized, systemImage: "arrow.clockwise")
                }
                .disabled(engine.isPurging)
            }

            Button(action: {
                Task {
                    await engine.purgeSelectedArtifacts()
                }
            }) {
                Label("清理选定产物".localized, systemImage: "trash")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(engine.isScanning || engine.isPurging || engine.totalArtifactBytes == 0)
        }
        .padding(18)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Directory Bar
    private var directoryBar: some View {
        HStack(spacing: 10) {
            Text("检索目录:".localized)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "folder")
                    .foregroundStyle(.tint)
                Text(engine.scanDirectory)
                    .font(.caption.monospaced())
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))

            Spacer()

            Button("更换目录".localized) {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                if panel.runModal() == .OK, let url = panel.url {
                    engine.scanDirectory = url.path
                    Task {
                        await engine.scanProjects(in: url.path)
                    }
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Artifacts List
    private var artifactsList: some View {
        List {
            ForEach(engine.artifacts) { item in
                HStack(spacing: 12) {
                    Toggle("", isOn: Binding(
                        get: { item.isSelected },
                        set: { val in
                            if let idx = engine.artifacts.firstIndex(where: { $0.id == item.id }) {
                                engine.artifacts[idx].isSelected = val
                            }
                        }
                    ))
                    .toggleStyle(.checkbox)
                    .labelsHidden()

                    Image(systemName: item.category.iconName)
                        .foregroundStyle(.tint)
                        .font(.title3)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(item.projectName)
                                .font(.subheadline.weight(.semibold))
                            Text("(\(item.category.rawValue))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text(item.artifactPath)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    Text(item.formattedSize)
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.inset)
    }
}

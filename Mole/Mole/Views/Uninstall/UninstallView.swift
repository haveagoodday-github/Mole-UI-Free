//
//  UninstallView.swift
//  Mole
//

import AppKit
import SwiftUI

public struct UninstallView: View {
    @ObservedObject var engine = UninstallEngine.shared
    @State private var selectedAppForInspector: InstalledApp?
    @State private var showConfirmDialog: Bool = false

    public init() {}

    public var body: some View {
        HSplitView {
            // Left: Apps List
            VStack(spacing: 0) {
                // Top Search and Filter Bar
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("搜索已安装应用名称或 Bundle ID...".localized, text: $engine.searchText)
                            .textFieldStyle(.plain)
                        if !engine.searchText.isEmpty {
                            Button(action: { engine.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))

                    if engine.isLoading {
                        Button(action: {
                            engine.cancelScan()
                        }) {
                            Label("取消".localized, systemImage: "xmark.circle.fill")
                        }
                        .tint(.red)
                    } else {
                        Button(action: {
                            Task {
                                await engine.scanInstalledApps()
                            }
                        }) {
                            Label("刷新".localized, systemImage: "arrow.clockwise")
                        }
                    }
                }
                .padding(14)
                .background(Color(NSColor.windowBackgroundColor))

                Divider()

                if !engine.installedApps.isEmpty {
                    VStack(spacing: 0) {
                        if engine.isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 14, height: 14)
                                Text("正在检索应用程序...".localized)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button(action: { engine.cancelScan() }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("取消".localized)
                                    }
                                    .font(.caption2)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.red)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.08))
                            Divider()
                        }
                        List(engine.filteredApps, selection: $selectedAppForInspector) { app in
                            appRow(app: app)
                                .tag(app)
                        }
                        .listStyle(.inset)
                    }
                } else if engine.isLoading {
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("正在扫描已安装应用程序及相关尺寸...".localized)
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
                    List(engine.filteredApps, selection: $selectedAppForInspector) { app in
                        appRow(app: app)
                            .tag(app)
                    }
                    .listStyle(.inset)
                }

                Divider()

                // Bottom App Count Bar
                HStack {
                    Text("共找到 %lld 个应用程序".localized(with: Int64(engine.installedApps.count)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor))
            }
            .frame(minWidth: 420)

            // Right: Remnant Detail & Uninstaller Panel
            VStack(spacing: 0) {
                if let app = selectedAppForInspector {
                    appDetailPanel(app: app)
                } else {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "app.badge.checkmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary.opacity(0.4))
                        Text("从左侧列表中选择一个应用".localized)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Mole 将自动深度扫描其隐藏在 Library 中的关联配置文件、缓存与支持文件".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(minWidth: 340)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        }
        .task {
            if engine.installedApps.isEmpty && !engine.isLoading {
                await engine.scanInstalledApps()
            }
        }
        .onChange(of: selectedAppForInspector?.id) { _ in
            if let app = selectedAppForInspector {
                Task {
                    await engine.scanRemnants(for: app)
                }
            }
        }
    }

    // MARK: - App Row
    private func appRow(app: InstalledApp) -> some View {
        HStack(spacing: 12) {
            Image(nsImage: app.icon)
                .resizable()
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(app.name)
                        .font(.subheadline.weight(.semibold))
                    if let ver = app.version {
                        Text("v\(ver)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(app.bundleIdentifier ?? app.path)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(app.formattedAppSize)
                    .font(.caption.weight(.semibold).monospacedDigit())
                if let lastUsed = app.lastUsedDate {
                    Text(lastUsed, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedAppForInspector = app
        }
    }

    // MARK: - App Detail Panel
    private func appDetailPanel(app: InstalledApp) -> some View {
        VStack(spacing: 0) {
            // App Header
            HStack(spacing: 14) {
                Image(nsImage: app.icon)
                    .resizable()
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.title3.weight(.bold))
                    Text(app.path)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text("体积占用: %@".localized(with: app.formattedTotalSize))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.tint)
                }
                Spacer()
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Remnants Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("深度关联残留文件".localized)
                        .font(.headline)
                    Spacer()
                    if engine.isScanningRemnants {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Text("%lld 个残留项".localized(with: Int64(app.remnants.count)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if app.remnants.isEmpty && !engine.isScanningRemnants {
                    Text("未发现额外的 Library 缓存或残留文件，仅安装包本身。".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                }

                List(app.remnants) { remnant in
                    HStack(spacing: 8) {
                        Image(systemName: remnant.type.iconName)
                            .foregroundStyle(.tint)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(remnant.name)
                                .font(.caption.weight(.medium))
                            Text(remnant.type.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(remnant.formattedSize)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.inset)
            }

            Divider()

            // Bottom Uninstall Button
            VStack(spacing: 8) {
                Button(action: {
                    showConfirmDialog = true
                }) {
                    Label("彻底卸载 %@".localized(with: app.name), systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .confirmationDialog(
            "确定要卸载 %@ 吗？".localized(with: app.name),
            isPresented: $showConfirmDialog,
            titleVisibility: .visible
        ) {
            Button("彻底卸载并清理所有关联残留".localized, role: .destructive) {
                Task {
                    await engine.uninstallApp(app, removeRemnants: true)
                    selectedAppForInspector = nil
                }
            }
            Button("仅删除应用本体".localized, role: .destructive) {
                Task {
                    await engine.uninstallApp(app, removeRemnants: false)
                    selectedAppForInspector = nil
                }
            }
            Button("取消".localized, role: .cancel) {}
        } message: {
            Text("此操作将移除应用及其在 Application Support、Preferences 和 Caches 中的所有配置与缓存数据。".localized)
        }
    }
}

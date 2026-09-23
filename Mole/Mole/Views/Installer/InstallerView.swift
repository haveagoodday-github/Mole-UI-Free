//
//  InstallerView.swift
//  Mole
//

import SwiftUI

public struct InstallerView: View {
    @ObservedObject var engine = ProjectPurgeEngine.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            Divider()

            // Main List
            if !engine.installers.isEmpty {
                VStack(spacing: 0) {
                    if engine.isScanning {
                        scanningBanner
                        Divider()
                    }
                    installerList
                }
            } else if engine.isScanning {
                VStack(spacing: 14) {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.2)
                    Text("正在检索下载与桌面目录中的 DMG / PKG 安装包...".localized)
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
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary.opacity(0.4))
                    Text("未发现残留的 DMG / PKG 安装文件".localized)
                        .font(.headline)
                    Text("通常软件安装完成后，存放在“下载”或“桌面”的安装镜像文件即可安全清理".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 30)
                    Spacer()
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
        .task {
            if engine.installers.isEmpty && !engine.isScanning {
                await engine.scanInstallers()
            }
        }
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
                Text("冗余安装包清理".localized)
                    .font(.title2.weight(.bold))
                HStack(spacing: 6) {
                    Text("可回收安装包空间:".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(ByteCountFormatter.string(fromByteCount: engine.totalInstallerBytes, countStyle: .file))
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
                        await engine.scanInstallers()
                    }
                }) {
                    Label("重新排查".localized, systemImage: "arrow.clockwise")
                }
                .disabled(engine.isPurging)
            }

            Button(action: {
                Task {
                    await engine.purgeSelectedInstallers()
                }
            }) {
                Label("清理选定安装包".localized, systemImage: "trash")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(engine.isScanning || engine.isPurging || engine.totalInstallerBytes == 0)
        }
        .padding(18)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Installer List
    private var installerList: some View {
        List {
            ForEach(engine.installers) { item in
                HStack(spacing: 12) {
                    Toggle("", isOn: Binding(
                        get: { item.isSelected },
                        set: { val in
                            if let idx = engine.installers.firstIndex(where: { $0.id == item.id }) {
                                engine.installers[idx].isSelected = val
                            }
                        }
                    ))
                    .toggleStyle(.checkbox)
                    .labelsHidden()

                    Image(systemName: item.name.hasSuffix(".dmg") ? "opticaldiscdrive.fill" : "shippingbox.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                        Text(item.path)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.formattedSize)
                            .font(.caption.weight(.semibold).monospacedDigit())
                        if let date = item.modificationDate {
                            Text(date, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.inset)
    }
}

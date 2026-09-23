//
//  PermissionGuideView.swift
//  Mole
//
//  Created by Kehong-IOS-Dev01 on 2026/9/23.
//

import SwiftUI

public struct PermissionGuideView: View {
    @ObservedObject var manager = PermissionManager.shared
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 14) {
                Image(systemName: manager.hasFullDiskAccess ? "checkmark.shield.fill" : "lock.shield.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(manager.hasFullDiskAccess ? Color.green : Color.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("全文件夹访问权限 (完全磁盘访问)".localized)
                        .font(.title2.weight(.bold))
                    Text("开启完全磁盘访问后，Mole 可直接访问所有文件夹，无需频繁弹出多个授权对话框，并能彻底扫描与清理受保护的系统与应用缓存。".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.top, 8)

            Divider()

            // Status Card
            HStack(spacing: 12) {
                Circle()
                    .fill(manager.hasFullDiskAccess ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(manager.hasFullDiskAccess ? "权限状态: 已成功开启全文件夹访问".localized : "权限状态: 尚未开启全文件夹访问".localized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(manager.hasFullDiskAccess ? Color.green : Color.orange)
                    Text(manager.hasFullDiskAccess ? "Mole 已获得全面文件读取与清理权限，所有深度清理与透视功能已就绪。".localized : "当前仅能访问受限目录，建议立即前往 macOS 系统设置完成授权。".localized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: {
                    manager.checkPermission()
                }) {
                    Label("重新检测".localized, systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(manager.hasFullDiskAccess ? Color.green.opacity(0.2) : Color.orange.opacity(0.2), lineWidth: 1))

            // Step-by-Step Instructions
            VStack(alignment: .leading, spacing: 14) {
                Text("申请与开启步骤:".localized)
                    .font(.subheadline.weight(.bold))

                instructionRow(
                    step: 1,
                    title: "前往系统设置".localized,
                    desc: "点击下方「打开系统设置」按钮，系统将直接打开【隐私与安全性 > 完全磁盘访问权限】页面。".localized
                )

                instructionRow(
                    step: 2,
                    title: "开启 Mole 授权".localized,
                    desc: "在右侧应用列表中找到【Mole】，点击右侧开关切换至开启状态。".localized
                )

                instructionRow(
                    step: 3,
                    title: "若列表中未显示 Mole（备用）".localized,
                    desc: "点击下方「在访达中显示 Mole」按钮，将访达中的 Mole 应用图标直接拖入系统设置的列表中即可。".localized
                )

                instructionRow(
                    step: 4,
                    title: "授权完成即时生效".localized,
                    desc: "开启后回到 Mole，应用将自动识别权限并点亮绿灯，无需重启应用。".localized
                )
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor).opacity(0.6)))

            Spacer()

            Divider()

            // Bottom Actions
            HStack(spacing: 12) {
                Button(action: {
                    manager.revealAppInFinder()
                }) {
                    Label("在访达中定位 Mole".localized, systemImage: "folder")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("完成".localized) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(action: {
                    manager.openFullDiskAccessSettings()
                }) {
                    Label("打开系统设置 (完全磁盘访问)".localized, systemImage: "gearshape")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.bottom, 6)
        }
        .padding(22)
        .frame(minWidth: 640, minHeight: 480)
        .onAppear {
            manager.checkPermission()
        }
    }

    private func instructionRow(step: Int, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 24, height: 24)
                Text("\(step)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(desc)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension Notification.Name {
    public static let showPermissionGuide = Notification.Name("showPermissionGuide")
}

#Preview {
    PermissionGuideView()
}

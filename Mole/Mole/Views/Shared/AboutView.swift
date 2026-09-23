//
//  AboutView.swift
//  Mole
//
//  Created by Kehong-IOS-Dev01 on 2026/9/23.
//

import SwiftUI

public extension Notification.Name {
    static let showAboutWindow = Notification.Name("showAboutWindow")
}

public struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared
    @AppStorage("show_tribute_on_launch") private var showTributeOnLaunch: Bool = true

    public init() {}

    private var isChinese: Bool {
        languageManager.currentLanguage != .en
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text(isChinese ? "开源致敬与版本说明" : "Open Source Tribute & About")
                        .font(.headline)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // App Identity Card
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [Color.blue.opacity(0.85), Color.purple.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 64, height: 64)
                                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)

                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("Mole for Mac")
                                    .font(.title2.weight(.bold))
                                Text("GUI Edition")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                                    .foregroundStyle(.tint)
                            }

                            Text(isChinese ? "基于开源项目 tw93/Mole 的原生 macOS 图形化系统清理与透视工具" : "Native macOS System Cleaner & Perspective Suite built upon tw93/Mole")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                Text("Version 1.0.0 (Build 2026.09)")
                                Text("•")
                                Text("GNU GPL-3.0 License")
                            }
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))

                    // Highlighted Tribute Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.thumbsup.fill")
                                .foregroundStyle(.orange)
                            Text(isChinese ? "开源代码致敬说明" : "Open Source Tribute Statement")
                                .font(.headline.weight(.bold))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(isChinese
                                ? "特别声明与由衷致敬：本软件是在 **Tw93** 先生原创并开源的 **Mole（https://github.com/tw93/Mole）** 开源代码之上，增加了原生 UI 交互体系迭代开发而成的 macOS 图形化客户端。"
                                : "Special Tribute & Acknowledgement: This software is iteratively developed by building a native macOS graphical user interface (GUI) on top of the open-source codebase of **Mole (https://github.com/tw93/Mole)** created by **Tw93**.")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(isChinese
                                ? "原项目作为一款广受好评、高效轻量的 macOS 终端清理与调优工具，为系统底层分析与垃圾清除提供了深厚扎实的技术基石。我们在完整继承原项目强劲能力的基础上，遵循 GPL-3.0 开源协议，为广大 Mac 用户带来了更加友好直观、可交互的可视化体验。"
                                : "As an outstanding and lightweight macOS terminal maintenance tool, the original project laid the solid foundation for system analysis and cache purging. Under the GNU GPL-3.0 license, we created this native UI edition to provide all Mac users with a visual, intuitive, and modern user experience.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isChinese ? "原项目作者" : "Original Author")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text("Tw93 (@HiTw93)")
                                    .font(.subheadline.weight(.semibold))
                            }

                            Spacer()

                            VStack(alignment: .leading, spacing: 2) {
                                Text(isChinese ? "原开源代码库" : "Original Repository")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text("github.com/tw93/Mole")
                                    .font(.subheadline.weight(.semibold))
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(isChinese ? "开源协议" : "Open Source License")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text("GNU GPL v3.0")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }

                        HStack(spacing: 12) {
                            Link(destination: URL(string: "https://github.com/tw93/Mole")!) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.right.square.fill")
                                    Text("访问原开源项目: https://github.com/tw93/Mole")
                                }
                                .font(.caption.weight(.semibold))
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)

                            Link(destination: URL(string: "https://www.gnu.org/licenses/gpl-3.0.html")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.text")
                                    Text(isChinese ? "GPL-3.0 协议全文" : "GPL-3.0 Full License")
                                }
                                .font(.caption.weight(.medium))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.25), lineWidth: 1))

                    // UI Evolution Highlights Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.purple)
                            Text(isChinese ? "在开源之上新增的 UI 交互与体验迭代" : "UI Iterations & Features Added on Top of CLI Core")
                                .font(.headline.weight(.semibold))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            featureRow(icon: "macwindow", color: .blue, title: isChinese ? "全原生 SwiftUI 图形界面" : "Native SwiftUI GUI", desc: isChinese ? "将复杂的终端参数封装为开箱即用的现代化 macOS 视窗与侧边栏导航，直观高效。" : "Encapsulates complex CLI parameters into intuitive macOS split-view windows.")
                            featureRow(icon: "chart.pie.fill", color: .orange, title: isChinese ? "磁盘空间透视 (Treemap / Perspective)" : "Disk Space Perspective", desc: isChinese ? "树状热力图多级下钻，大文件毫秒级定位，后台非阻塞分析且支持随时打断取消。" : "Interactive treemap deep dive, locating large files with non-blocking instant cancellation.")
                            featureRow(icon: "wand.and.stars", color: .purple, title: isChinese ? "交互式系统深度清理" : "Interactive Deep System Clean", desc: isChinese ? "20+ 缓存与日志分类浏览，支持按需单选/全选、实时流式增量展示及安全白名单保护。" : "Browse 20+ cache and log categories with fine-grained checkboxes, streaming scan results, and safety whitelists.")
                            featureRow(icon: "trash.circle.fill", color: .red, title: isChinese ? "应用彻底卸载与残留分析" : "Application Thorough Uninstall", desc: isChinese ? "图形化扫描应用本体及其 Application Support、Preferences 残留，一键彻底移除。" : "Visual detection of app binaries and remnant files across Library folders.")
                            featureRow(icon: "gauge.with.needle.fill", color: .green, title: isChinese ? "系统仪表盘与非阻塞监控" : "Hardware Dashboard", desc: isChinese ? "图形化展示 CPU、内存、电池健康与磁盘读写，支持 1 秒极速监控且默认免打扰。" : "Real-time metrics for CPU, RAM, battery and disk I/O with 1s refresh interval support.")
                            featureRow(icon: "lock.shield.fill", color: .teal, title: isChinese ? "全文件夹访问 (Full Disk Access) 引导体系" : "Direct Full Disk Access Guide", desc: isChinese ? "直接申请完全磁盘访问权限，切回即时生效，彻底消除碎片化的多次文件夹授权弹窗。" : "Direct FDA permission guidance with zero-configuration live status recheck.")
                            featureRow(icon: "globe", color: .indigo, title: isChinese ? "原生多语言支持" : "Multi-language Localization", desc: isChinese ? "完整适配简体中文、繁体中文 (香港/台湾) 以及英文。" : "Full support for English, Simplified Chinese, and Traditional Chinese.")
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))

                    // Independence & Open Source Notice
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text(isChinese ? "声明与授权" : "Notice & Licensing")
                                .font(.subheadline.weight(.semibold))
                        }
                        Text(isChinese
                            ? "1. 本项目采用 GNU General Public License v3.0 (GPL-3.0) 开源协议，代码完全开放。\n2. 本项目由开源社区自主迭代开发，与商业专有软件「Mole for Mac (mole.fit)」无商业从属关系。\n3. 再次向原作者 Tw93 以及所有开源贡献者的无私奉献致以崇高敬意！"
                            : "1. This project is licensed under the GNU General Public License v3.0 (GPL-3.0).\n2. This project is developed independently by the open-source community and is not affiliated with the commercial entity 'Mole for Mac (mole.fit)'.\n3. Our sincere gratitude to Tw93 and all open-source contributors!")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor).opacity(0.5)))
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
            }

            Divider()

            // Bottom Actions Bar
            HStack(spacing: 12) {
                Toggle(isChinese ? "每次打开应用时显示此致敬说明" : "Show this tribute upon launch", isOn: $showTributeOnLaunch)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: {
                    if let url = URL(string: "https://github.com/tw93/Mole") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label(isChinese ? "前往 GitHub 查看原项目" : "Visit Original Repository", systemImage: "arrow.up.right")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Button(action: { dismiss() }) {
                    Text(isChinese ? "我知道了，开始使用" : "Got it, Get Started")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 620, idealWidth: 660, maxWidth: 700, minHeight: 560, idealHeight: 620, maxHeight: 720)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(desc)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    AboutView()
}

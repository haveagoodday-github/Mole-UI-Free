//
//  ContentView.swift
//  Mole
//
//  Created by Kehong-IOS-Dev01 on 2026/9/23.
//

import SwiftUI

public enum NavigationTab: String, CaseIterable, Identifiable {
    case dashboard = "dashboard"
    case clean = "clean"
    case uninstall = "uninstall"
    case analyze = "analyze"
    case optimize = "optimize"
    case purge = "purge"
    case installer = "installer"
    case terminal = "terminal"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .dashboard: return "系统仪表盘".localized
        case .clean: return "深度系统清理".localized
        case .uninstall: return "应用彻底卸载".localized
        case .analyze: return "磁盘空间透视".localized
        case .optimize: return "系统维护优化".localized
        case .purge: return "工程构建清理".localized
        case .installer: return "安装镜像包清理".localized
        case .terminal: return "Mole 终端日志".localized
        }
    }

    public var icon: String {
        switch self {
        case .dashboard: return "gauge.with.needle"
        case .clean: return "wand.and.stars"
        case .uninstall: return "trash.circle"
        case .analyze: return "chart.pie.fill"
        case .optimize: return "bolt.fill"
        case .purge: return "hammer.fill"
        case .installer: return "shippingbox.fill"
        case .terminal: return "terminal.fill"
        }
    }
}

public enum ActiveSheet: String, Identifiable {
    case tribute = "tribute"
    case permission = "permission"
    case terminal = "terminal"

    public var id: String { rawValue }
}

public struct ContentView: View {
    @State private var selectedTab: NavigationTab? = .dashboard
    @AppStorage("show_tribute_on_launch") private var showTributeOnLaunch: Bool = true
    @State private var activeSheet: ActiveSheet? = nil
    @State private var showPermissionBanner: Bool = true
    @ObservedObject var runner = MoleProcessRunner.shared
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var permissionManager = PermissionManager.shared

    public init() {}

    public var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // Brand Header
                HStack(spacing: 10) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.title2)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mole")
                            .font(.headline.weight(.bold))
                        Text("Clean & Optimize macOS")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider()

                // Navigation List
                List(NavigationTab.allCases, selection: $selectedTab) { tab in
                    NavigationLink(value: tab) {
                        Label {
                            Text(tab.title)
                                .font(.subheadline)
                        } icon: {
                            Image(systemName: tab.icon)
                                .foregroundStyle(tabColor(for: tab))
                        }
                    }
                }
                .listStyle(.sidebar)

                Divider()

                // Bottom Status Bar
                HStack(spacing: 8) {
                    Circle()
                        .fill(runner.isRunningCommand ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(runner.isRunningCommand ? "正在执行任务...".localized : "就绪".localized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(action: { activeSheet = .permission }) {
                        HStack(spacing: 3) {
                            Image(systemName: permissionManager.hasFullDiskAccess ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                                .font(.caption)
                                .foregroundStyle(permissionManager.hasFullDiskAccess ? Color.green : Color.orange)
                            Text(permissionManager.hasFullDiskAccess ? "全文件夹访问".localized : "申请权限".localized)
                                .font(.caption2)
                                .foregroundStyle(permissionManager.hasFullDiskAccess ? Color.secondary : Color.orange)
                        }
                    }
                    .buttonStyle(.plain)
                    .help(permissionManager.hasFullDiskAccess ? "全文件夹访问: 已开启".localized : "全文件夹访问: 未开启 (点击申请)".localized)

                    Menu {
                        ForEach(AppLanguage.allCases) { lang in
                            Button(action: { languageManager.setLanguage(lang) }) {
                                HStack {
                                    Text(lang.displayName)
                                    if languageManager.currentLanguage == lang {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "globe")
                            Text(languageManager.currentLanguage.displayName)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .help("语言 / Language".localized)

                    Button(action: { activeSheet = .terminal }) {
                        Image(systemName: "terminal")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("查看 Mole 实时输出终端".localized)

                    Button(action: { activeSheet = .tribute }) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("关于与开源致敬 / About & Credits".localized)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(NSColor.controlBackgroundColor))
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            VStack(spacing: 0) {
                // Top Full Disk Access Banner
                if !permissionManager.hasFullDiskAccess && showPermissionBanner {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundStyle(.orange)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("全文件夹访问权限未开启".localized)
                                .font(.subheadline.weight(.semibold))
                            Text("Mole 推荐直接开启「完全磁盘访问权限」，无需频繁弹出多个文件夹授权，并能彻底分析与清理受保护系统目录。".localized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("直接申请全文件夹访问".localized) {
                            permissionManager.openFullDiskAccessSettings()
                            activeSheet = .permission
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button("查看指引".localized) {
                            activeSheet = .permission
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button(action: {
                            withAnimation {
                                showPermissionBanner = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.12))
                    .overlay(Divider(), alignment: .bottom)
                }

                // Detail Page
                Group {
                    switch selectedTab {
                    case .dashboard, .none:
                        DashboardView(selectedTab: Binding(
                            get: { selectedTab?.rawValue ?? "dashboard" },
                            set: { selectedTab = NavigationTab(rawValue: $0) }
                        ))
                    case .clean:
                        CleanView()
                    case .uninstall:
                        UninstallView()
                    case .analyze:
                        AnalyzeView()
                    case .optimize:
                        OptimizeView()
                    case .purge:
                        PurgeView()
                    case .installer:
                        InstallerView()
                    case .terminal:
                        TerminalLogView()
                    }
                }
                .navigationTitle(selectedTab?.title ?? "Mole")
            }
        }
        .environment(\.locale, languageManager.currentLanguage.locale)
        .id(languageManager.currentLanguage)
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .tribute:
                    AboutView()
                case .permission:
                    PermissionGuideView()
                case .terminal:
                    VStack(spacing: 0) {
                        HStack {
                            Text("Mole 实时日志".localized)
                                .font(.headline)
                            Spacer()
                            Button("关闭".localized) {
                                activeSheet = nil
                            }
                        }
                        .padding()
                        Divider()
                        TerminalLogView()
                    }
                    .frame(minWidth: 700, minHeight: 400)
                }
            }
            .environment(\.locale, languageManager.currentLanguage.locale)
            .id(languageManager.currentLanguage)
        }
        .onAppear {
            if showTributeOnLaunch {
                activeSheet = .tribute
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAboutWindow)) { _ in
            activeSheet = .tribute
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPermissionGuide)) { _ in
            activeSheet = .permission
        }
    }

    private func tabColor(for tab: NavigationTab) -> Color {
        switch tab {
        case .dashboard: return .blue
        case .clean: return .purple
        case .uninstall: return .red
        case .analyze: return .orange
        case .optimize: return .yellow
        case .purge: return .mint
        case .installer: return .indigo
        case .terminal: return .teal
        }
    }
}

#Preview {
    ContentView()
}

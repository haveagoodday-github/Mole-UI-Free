//
//  DashboardView.swift
//  Mole
//

import Charts
import SwiftUI

public struct DashboardView: View {
    @ObservedObject var monitor = StatusMonitorService.shared
    @ObservedObject var cleanEngine = CleanEngine.shared
    @ObservedObject var optimizeEngine = OptimizeEngine.shared
    @Binding var selectedTab: String

    public init(selectedTab: Binding<String>) {
        self._selectedTab = selectedTab
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Notice banner when live monitoring is disabled
                if !monitor.isLiveMonitoringEnabled {
                    disabledMonitoringPromptBanner
                }

                // Top Header: Hardware Overview & Health Score
                headerCard

                // Core Metrics Grid: CPU, Memory, Disk, Network
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    cpuCard
                    memoryCard
                    diskCard
                    networkCard
                }

                // Top Processes Table
                topProcessesCard
            }
            .padding(20)
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Toggle("实时检测".localized, isOn: $monitor.isLiveMonitoringEnabled)
                    .toggleStyle(.switch)
                    .help("开启或暂停后台实时检测更新".localized)

                Picker("频率".localized, selection: $monitor.updateInterval) {
                    ForEach(MonitorUpdateInterval.allCases) { interval in
                        Text(interval.title).tag(interval)
                    }
                }
                .pickerStyle(.menu)
                .disabled(!monitor.isLiveMonitoringEnabled)
                .help("配置自动检测更新时间间隔".localized)

                Button(action: {
                    Task {
                        await monitor.fetchStatus(isManual: true)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("手动刷新".localized)
                    }
                }
                .disabled(monitor.isLoading)
                .help("立即重新检测系统状态".localized)
            }
        }
    }

    // MARK: - Disabled Monitoring Prompt Banner
    private var disabledMonitoringPromptBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "pause.circle.fill")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("实时检测已关闭".localized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("系统当前处于手动检测模式，数据不会自动刷新。你可以随时开启实时自动检测，或点击右上角手动刷新。".localized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: {
                monitor.isLiveMonitoringEnabled = true
            }) {
                Label("开启实时检测".localized, systemImage: "play.fill")
                    .font(.caption.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.orange.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Header Card
    private var headerCard: some View {
        let snap = monitor.snapshot
        let hw = snap?.hardware

        return HStack(spacing: 16) {
            Image(systemName: "laptopcomputer.and.iphone")
                .font(.system(size: 38))
                .foregroundStyle(.tint)
                .frame(width: 54, height: 54)
                .background(Circle().fill(Color.accentColor.opacity(0.12)))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(hw?.model ?? "Mac")
                        .font(.title2.weight(.bold))
                    if let chip = hw?.cpuModel {
                        Text(chip)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.primary.opacity(0.08)))
                    }
                }

                HStack(spacing: 12) {
                    Label(hw?.osVersion ?? "macOS", systemImage: "apple.logo")
                    Label("内存: %@".localized(with: hw?.totalRam ?? "--"), systemImage: "memorychip")
                    Label("运行时长: %@".localized(with: snap?.uptime ?? "--"), systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // Live Monitoring Status Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(monitor.isLiveMonitoringEnabled && monitor.updateInterval != .manual ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)

                    if monitor.isLiveMonitoringEnabled && monitor.updateInterval != .manual {
                        Text("实时检测开启 (%@更新)".localized(with: monitor.updateInterval.title))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.primary)
                    } else {
                        Text("实时检测已关闭 (手动更新)".localized)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                    }

                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("上次检测: %@".localized(with: monitor.formattedLastUpdated))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)

                    if monitor.isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 14, height: 14)
                    }
                }
                .padding(.top, 2)
            }

            Spacer()

            // Health Score Badge
            if let score = snap?.healthScore {
                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(score >= 80 ? .green : (score >= 60 ? .orange : .red))
                    Text("系统健康度".localized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(NSColor.controlBackgroundColor)))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - CPU Card
    private var cpuCard: some View {
        let cpu = monitor.snapshot?.cpu
        let usage = cpu?.usage ?? 0.0

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("中央处理器 (CPU)".localized, systemImage: "cpu")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f%%", usage))
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(usage > 80 ? .red : (usage > 50 ? .orange : .primary))
            }

            // Progress Bar
            ProgressView(value: min(max(usage / 100.0, 0), 1.0))
                .tint(usage > 80 ? .red : (usage > 50 ? .orange : .blue))

            // Per core mini bars
            if let cores = cpu?.perCore, !cores.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("%lld 核心实时状态:".localized(with: Int64(cores.count)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        ForEach(Array(cores.enumerated()), id: \.offset) { _, coreUsage in
                            GeometryReader { geo in
                                VStack {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(coreUsage > 75 ? Color.red : Color.blue.opacity(0.85))
                                        .frame(height: max(geo.size.height * CGFloat(coreUsage / 100.0), 3))
                                }
                            }
                            .frame(height: 28)
                        }
                    }
                }
            }

            HStack {
                Text("负载均值: %@".localized(with: String(format: "%.2f, %.2f, %.2f", cpu?.load1 ?? 0, cpu?.load5 ?? 0, cpu?.load15 ?? 0)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(NSColor.controlBackgroundColor)))
        .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
    }

    // MARK: - Memory Card
    private var memoryCard: some View {
        let mem = monitor.snapshot?.memory
        let pct = mem?.usedPercent ?? 0.0
        let usedGB = Double(mem?.used ?? 0) / (1024 * 1024 * 1024)
        let totalGB = Double(mem?.total ?? 0) / (1024 * 1024 * 1024)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("系统内存 (RAM)".localized, systemImage: "memorychip")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f%%", pct))
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(pct > 85 ? .red : (pct > 70 ? .orange : .primary))
            }

            ProgressView(value: min(max(pct / 100.0, 0), 1.0))
                .tint(pct > 85 ? .red : (pct > 70 ? .orange : .purple))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("已用: %@ / %@".localized(with: String(format: "%.1f GB", usedGB), String(format: "%.1f GB", totalGB)))
                        .font(.caption.weight(.medium))
                    if let cached = mem?.cached {
                        Text("缓存占用: %@".localized(with: ByteCountFormatter.string(fromByteCount: cached, countStyle: .memory)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let swap = mem?.swapUsed, swap > 0 {
                    Text("交换空间: %@".localized(with: ByteCountFormatter.string(fromByteCount: swap, countStyle: .memory)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: {
                selectedTab = "optimize"
            }) {
                Label("优化释放内存".localized, systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(NSColor.controlBackgroundColor)))
        .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
    }

    // MARK: - Disk Card
    private var diskCard: some View {
        let primaryDisk = monitor.snapshot?.disks?.first(where: { $0.mount == "/" }) ?? monitor.snapshot?.disks?.first
        let pct = primaryDisk?.usedPercent ?? 0.0
        let used = primaryDisk?.used ?? 0
        let total = primaryDisk?.total ?? 1

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("系统主磁盘 (APFS)".localized, systemImage: "internaldrive")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f%%", pct))
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(pct > 90 ? .red : (pct > 75 ? .orange : .primary))
            }

            ProgressView(value: min(max(pct / 100.0, 0), 1.0))
                .tint(pct > 90 ? .red : (pct > 75 ? .orange : .mint))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("已用: %@ / %@".localized(with: ByteCountFormatter.string(fromByteCount: used, countStyle: .file), ByteCountFormatter.string(fromByteCount: total, countStyle: .file)))
                        .font(.caption.weight(.medium))
                    let free = max(total - used, 0)
                    Text("剩余可用空间: %@".localized(with: ByteCountFormatter.string(fromByteCount: free, countStyle: .file)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack {
                Button(action: {
                    selectedTab = "clean"
                }) {
                    Label("一键系统清理".localized, systemImage: "wand.and.stars")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button(action: {
                    selectedTab = "analyze"
                }) {
                    Label("透视磁盘".localized, systemImage: "chart.pie")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(NSColor.controlBackgroundColor)))
        .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
    }

    // MARK: - Network Card
    private var networkCard: some View {
        let activeNet = monitor.snapshot?.network?.first(where: { ($0.ip ?? "") != "" }) ?? monitor.snapshot?.network?.first
        let rx = activeNet?.rxRateMbs ?? 0.0
        let tx = activeNet?.txRateMbs ?? 0.0

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("网络活动".localized, systemImage: "network")
                    .font(.headline)
                Spacer()
                if let ip = activeNet?.ip, !ip.isEmpty {
                    Text(ip)
                        .font(.caption.weight(.semibold).monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 24) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("下行下载".localized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f MB/s", rx))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("上行上传".localized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f MB/s", tx))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                    }
                }
            }
            .padding(.vertical, 4)

            HStack {
                Text("网卡: %@".localized(with: activeNet?.name ?? "en0"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(NSColor.controlBackgroundColor)))
        .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
    }

    // MARK: - Top Processes Table
    private var topProcessesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("活跃高占用进程".localized, systemImage: "list.bullet.rectangle")
                    .font(.headline)
                Spacer()
                Text("实时 Top 5 资源排行".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if let procs = monitor.snapshot?.topProcesses, !procs.isEmpty {
                VStack(spacing: 8) {
                    ForEach(procs) { p in
                        HStack {
                            Text("\(p.pid)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .frame(width: 48, alignment: .leading)

                            Text(p.name)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)

                            Spacer()

                            Text(String(format: "CPU: %.1f%%", p.cpu ?? 0))
                                .font(.caption.weight(.semibold).monospacedDigit())
                                .foregroundStyle((p.cpu ?? 0) > 30 ? .red : .primary)
                                .frame(width: 100, alignment: .trailing)

                            if let memBytes = p.memoryBytes {
                                Text(ByteCountFormatter.string(fromByteCount: memBytes, countStyle: .memory))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 90, alignment: .trailing)
                            }
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
            } else {
                Text("正在加载进程监控数据...".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(NSColor.controlBackgroundColor)))
        .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
    }
}

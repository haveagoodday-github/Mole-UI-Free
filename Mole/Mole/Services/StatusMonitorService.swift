//
//  StatusMonitorService.swift
//  Mole
//

import Combine
import Foundation

public enum MonitorUpdateInterval: Double, CaseIterable, Identifiable {
    case seconds1 = 1.0
    case seconds5 = 5.0
    case seconds10 = 10.0
    case seconds30 = 30.0
    case manual = 0.0

    public var id: Double { rawValue }

    public var title: String {
        switch self {
        case .seconds1: return "1 秒".localized
        case .seconds5: return "5 秒".localized
        case .seconds10: return "10 秒".localized
        case .seconds30: return "30 秒".localized
        case .manual: return "手动更新".localized
        }
    }
}

@MainActor
public final class StatusMonitorService: ObservableObject {
    public static let shared = StatusMonitorService()

    @Published public var snapshot: SystemStatusSnapshot?
    @Published public var isLoading: Bool = false
    @Published public var lastUpdated: Date?
    @Published public var errorMessage: String?

    // Default to false as requested
    @Published public var isLiveMonitoringEnabled: Bool = false {
        didSet {
            applyMonitoringSettings()
        }
    }

    @Published public var updateInterval: MonitorUpdateInterval = .seconds5 {
        didSet {
            applyMonitoringSettings()
        }
    }

    private var timer: Timer?
    private var isFetching: Bool = false
    private let runner = MoleProcessRunner.shared

    private init() {
        applyMonitoringSettings()
        Task {
            await fetchStatus(isManual: true)
        }
    }

    public func applyMonitoringSettings() {
        stopTimer()

        guard isLiveMonitoringEnabled && updateInterval != .manual else {
            return
        }

        let interval = updateInterval.rawValue
        let newTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchStatus(isManual: false)
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        self.timer = newTimer
    }

    public func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    public func fetchStatus(isManual: Bool = false) async {
        guard !isFetching else { return }
        isFetching = true

        if isManual {
            isLoading = true
        }

        defer {
            isFetching = false
            if isManual {
                isLoading = false
            }
        }

        guard let statusBin = runner.resolveExecutable(named: "status-go") else {
            self.errorMessage = "未找到 status-go 二进制文件"
            return
        }

        let result = await runner.runShellCommand("\"\(statusBin)\" -json", silent: true)
        guard result.exitCode == 0, let data = result.output.data(using: .utf8) else {
            if self.snapshot == nil {
                self.errorMessage = "获取系统状态失败: \(result.output)"
            }
            return
        }

        do {
            // Offload JSON decoding to background thread to never block UI
            let parsed = try await Task.detached {
                try JSONDecoder().decode(SystemStatusSnapshot.self, from: data)
            }.value
            self.snapshot = parsed
            self.lastUpdated = Date()
            self.errorMessage = nil
        } catch {
            print("Failed to decode status json: \(error)")
        }
    }

    public var formattedLastUpdated: String {
        guard let date = lastUpdated else { return "未更新" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

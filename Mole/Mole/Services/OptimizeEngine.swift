//
//  OptimizeEngine.swift
//  Mole
//

import Combine
import Foundation

@MainActor
public final class OptimizeEngine: ObservableObject {
    public static let shared = OptimizeEngine()

    @Published public var tasks: [OptimizeTask] = OptimizeTask.defaultTasks
    @Published public var isRunningAny: Bool = false
    @Published public var overallProgress: Double = 0.0

    private let runner = MoleProcessRunner.shared

    private init() {}

    public func selectAll(_ select: Bool) {
        for index in tasks.indices {
            tasks[index].isSelected = select
        }
    }

    /// Run a single optimization task
    public func runTask(_ task: OptimizeTask) async {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        tasks[index].state = .running
        runner.appendLog("⚡️ 开始执行维护任务: \(task.title)")

        let result = await runner.runShellCommand(task.command)

        if result.exitCode == 0 {
            tasks[index].state = .completed(message: "维护优化完成")
            runner.appendLog("✅ \(task.title) 完成")
        } else {
            tasks[index].state = .failed(message: "执行遇到异常 (代码 %lld)".localized(with: Int64(result.exitCode)))
            runner.appendLog("⚠️ \(task.title) 返回代码 \(result.exitCode)")
        }
    }

    private var currentOptimizeTask: Task<Void, Never>?

    /// Stop/cancel all ongoing optimization tasks immediately
    public func cancelAll() {
        currentOptimizeTask?.cancel()
        currentOptimizeTask = nil
        for idx in tasks.indices where tasks[idx].state == .running {
            tasks[idx].state = .idle
        }
        isRunningAny = false
        runner.appendLog("⏹ 维护优化任务已由用户停止")
    }

    /// Run all selected tasks sequentially
    public func runAllSelected() async {
        currentOptimizeTask?.cancel()

        let task = Task { [weak self] in
            guard let self = self else { return }
            await self.performRunAllSelected()
        }
        currentOptimizeTask = task
        await task.value
    }

    private func performRunAllSelected() async {
        isRunningAny = true
        overallProgress = 0.0

        let selectedIndices = tasks.indices.filter { tasks[$0].isSelected }
        guard !selectedIndices.isEmpty else {
            isRunningAny = false
            return
        }

        let total = Double(selectedIndices.count)
        for (step, idx) in selectedIndices.enumerated() {
            if Task.isCancelled { break }

            tasks[idx].state = .running
            let task = tasks[idx]
            runner.appendLog("⚡️ [\(step + 1)/\(selectedIndices.count)] 正在优化: \(task.title)")

            let res = await runner.runShellCommand(task.command)
            if Task.isCancelled {
                tasks[idx].state = .idle
                break
            }

            if res.exitCode == 0 {
                tasks[idx].state = .completed(message: "已成功执行")
            } else {
                tasks[idx].state = .failed(message: "退出码 %lld".localized(with: Int64(res.exitCode)))
            }

            overallProgress = Double(step + 1) / total
        }

        isRunningAny = false
    }
}

//
//  OptimizeView.swift
//  Mole
//

import SwiftUI

public struct OptimizeView: View {
    @ObservedObject var engine = OptimizeEngine.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            Divider()

            // Task List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(engine.tasks) { task in
                        taskCard(task: task)
                    }
                }
                .padding(18)
            }
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("系统维护与深度优化".localized)
                    .font(.title2.weight(.bold))
                Text("定期执行系统缓存刷新、DNS 重置与数据库碎片整理，保持系统轻快响应".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if engine.isRunningAny {
                Button(action: {
                    engine.cancelAll()
                }) {
                    Label("停止执行".localized, systemImage: "stop.fill")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Button(action: {
                    Task {
                        await engine.runAllSelected()
                    }
                }) {
                    Label("一键执行选中任务".localized, systemImage: "bolt.fill")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Task Card
    private func taskCard(task: OptimizeTask) -> some View {
        HStack(spacing: 14) {
            Toggle("", isOn: Binding(
                get: { task.isSelected },
                set: { val in
                    if let idx = engine.tasks.firstIndex(where: { $0.id == task.id }) {
                        engine.tasks[idx].isSelected = val
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
            .disabled(engine.isRunningAny)

            Image(systemName: task.iconName)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(0.12)))

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                Text(task.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Execution Status / Action Button
            switch task.state {
            case .idle:
                Button("单独运行".localized) {
                    Task {
                        await engine.runTask(task)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(engine.isRunningAny)

            case .running:
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("执行中...".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .completed(let msg):
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(msg.localized)
                        .font(.caption)
                        .foregroundStyle(.green)
                }

            case .failed(let msg):
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(msg.localized)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}

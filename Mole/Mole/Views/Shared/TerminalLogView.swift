//
//  TerminalLogView.swift
//  Mole
//

import SwiftUI

public struct TerminalLogView: View {
    @ObservedObject var runner = MoleProcessRunner.shared
    @State private var autoScroll: Bool = true

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color.red.opacity(0.8)).frame(width: 10, height: 10)
                    Circle().fill(Color.yellow.opacity(0.8)).frame(width: 10, height: 10)
                    Circle().fill(Color.green.opacity(0.8)).frame(width: 10, height: 10)
                    Text("Mole 实时运行终端".localized)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 6)
                }

                Spacer()

                Toggle("自动滚动".localized, isOn: $autoScroll)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Button(action: { runner.clearLogs() }) {
                    Label("清空控制台".localized, systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Console output area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        if runner.logEntries.isEmpty {
                            Text("// Mole 终端日志就绪，执行清理或维护任务时将在此实时显示详细底层输出...".localized)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.gray.opacity(0.6))
                                .padding(.top, 16)
                        } else {
                            ForEach(Array(runner.logEntries.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(logColor(for: line))
                                    .textSelection(.enabled)
                                    .id(index)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(NSColor.black))
                .onChange(of: runner.logEntries.count) { _ in
                    if autoScroll, !runner.logEntries.isEmpty {
                        proxy.scrollTo(runner.logEntries.count - 1, anchor: .bottom)
                    }
                }
            }
        }
        .frame(minHeight: 200)
    }

    private func logColor(for line: String) -> Color {
        if line.contains("❌") || line.contains("[stderr]") || line.contains("failed") || line.contains("Error") {
            return Color.red.opacity(0.9)
        } else if line.contains("⚠️") || line.contains("warning") {
            return Color.yellow.opacity(0.9)
        } else if line.contains("✅") || line.contains("完成") || line.contains("Success") {
            return Color.green.opacity(0.9)
        } else if line.hasPrefix("❯") || line.hasPrefix("⚡️") {
            return Color.cyan.opacity(0.9)
        }
        return Color.white.opacity(0.85)
    }
}

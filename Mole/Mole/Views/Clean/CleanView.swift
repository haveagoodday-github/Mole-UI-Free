//
//  CleanView.swift
//  Mole
//

import SwiftUI

public struct CleanView: View {
    @ObservedObject var engine = CleanEngine.shared
    @State private var expandedCategories: Set<CleanCategoryType> = Set(CleanCategoryType.allCases)

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Top Action Bar
            topActionBar

            Divider()

            // Main Content Area
            if engine.isCleaning {
                cleaningStateView
            } else if !engine.items.isEmpty {
                VStack(spacing: 0) {
                    if engine.isScanning {
                        scanningBanner
                        Divider()
                    }
                    itemListScrollView
                }
            } else if engine.isScanning {
                scanningStateView
            } else {
                emptyStateView
            }
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
        .task {
            if engine.items.isEmpty && !engine.isScanning {
                await engine.scanAll()
            }
        }
    }

    // MARK: - Scanning Banner (when items are already present)
    private var scanningBanner: some View {
        HStack(spacing: 12) {
            ProgressView(value: engine.scanProgress)
                .frame(width: 140)
            Text("正在扫描系统与应用缓存 (%.0f%%)...".localized(with: engine.scanProgress * 100))
                .font(.caption)
                .foregroundStyle(.secondary)

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
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.08))
    }

    // MARK: - Top Action Bar
    private var topActionBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("深度系统清理".localized)
                    .font(.title2.weight(.bold))
                HStack(spacing: 8) {
                    Text("发现可清理: %@".localized(with: engine.formattedTotalReclaimable))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text("已勾选: %@".localized(with: engine.formattedTotalSelected))
                        .font(.caption.weight(.semibold))
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
                        await engine.scanAll()
                    }
                }) {
                    Label("重新扫描".localized, systemImage: "arrow.clockwise")
                }
                .disabled(engine.isCleaning)
            }

            Button(action: {
                Task {
                    await engine.performClean()
                }
            }) {
                Label("立即清理选定项 (%@)".localized(with: engine.formattedTotalSelected), systemImage: "sparkles")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .disabled(engine.isScanning || engine.isCleaning || engine.totalSelectedBytes == 0)
        }
        .padding(18)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Items List
    private var itemListScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                // Select All / Deselect All Controls
                HStack {
                    Button(action: { engine.selectAll(true) }) {
                        Text("全选所有项".localized)
                            .font(.caption)
                    }
                    Button(action: { engine.selectAll(false) }) {
                        Text("取消全选".localized)
                            .font(.caption)
                    }
                    Spacer()
                    if engine.lastCleanedBytes > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("上次已释放: %@".localized(with: ByteCountFormatter.string(fromByteCount: engine.lastCleanedBytes, countStyle: .file)))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 2)

                // Category Sections
                ForEach(CleanCategoryType.allCases) { category in
                    let categoryItems = engine.items(for: category)
                    if !categoryItems.isEmpty {
                        categoryCard(category: category, items: categoryItems)
                    }
                }
            }
            .padding(18)
        }
    }

    // MARK: - Category Card
    private func categoryCard(category: CleanCategoryType, items: [CleanItem]) -> some View {
        let isExpanded = expandedCategories.contains(category)
        let totalCatBytes = items.reduce(0) { $0 + $1.sizeInBytes }
        let allSelected = items.allSatisfy { $0.isSelected }

        return VStack(spacing: 0) {
            // Category Header
            HStack(spacing: 10) {
                Toggle("", isOn: Binding(
                    get: { allSelected },
                    set: { engine.toggleCategory(category, isSelected: $0) }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()

                Image(systemName: category.iconName)
                    .foregroundStyle(.tint)
                    .font(.title3)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.title)
                        .font(.headline)
                    Text(category.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(ByteCountFormatter.string(fromByteCount: totalCatBytes, countStyle: .file))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)

                Button(action: {
                    if isExpanded {
                        expandedCategories.remove(category)
                    } else {
                        expandedCategories.insert(category)
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))

            // Child Items
            if isExpanded {
                Divider()
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        itemRow(item: item)
                        if item.id != items.last?.id {
                            Divider().padding(.leading, 42)
                        }
                    }
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Item Row
    private func itemRow(item: CleanItem) -> some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { val in
                    if let idx = engine.items.firstIndex(where: { $0.id == item.id }) {
                        engine.items[idx].isSelected = val
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                Text(item.path)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text(item.formattedSize)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Scanning State
    private var scanningStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView(value: engine.scanProgress)
                .progressViewStyle(.circular)
                .scaleEffect(1.3)

            Text("正在扫描系统、应用与开发者缓存...".localized)
                .font(.headline)

            ProgressView(value: engine.scanProgress)
                .frame(maxWidth: 300)

            Text("已完成: %.0f%%".localized(with: engine.scanProgress * 100))
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(role: .cancel, action: {
                engine.cancelScan()
            }) {
                Label("取消扫描".localized, systemImage: "xmark.circle")
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .padding(.top, 4)

            Spacer()
        }
    }

    // MARK: - Cleaning State
    private var cleaningStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.4)

            Text("正在安全清理选定项...".localized)
                .font(.headline)

            ProgressView(value: engine.cleanProgress)
                .frame(maxWidth: 320)

            Text("Mole 正在执行安全清理与缓存释放，请稍候...".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 54))
                .foregroundStyle(.green)

            Text("系统整洁，未发现显著垃圾文件".localized)
                .font(.title3.weight(.bold))

            Text("所有系统与应用程序缓存均在健康水位".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("重新全面体检".localized) {
                Task {
                    await engine.scanAll()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
            Spacer()
        }
    }
}

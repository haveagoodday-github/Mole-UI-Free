//
//  CleanItem.swift
//  Mole
//

import Foundation

public enum CleanCategoryType: String, CaseIterable, Identifiable, Codable {
    case userCaches = "user_caches"
    case appCaches = "app_caches"
    case devCaches = "dev_caches"
    case systemLogs = "system_logs"
    case appLeftovers = "app_leftovers"
    case trash = "trash"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .userCaches: return "用户与系统缓存".localized
        case .appCaches: return "应用缓存与临时数据".localized
        case .devCaches: return "开发者缓存与构建产物".localized
        case .systemLogs: return "系统日志与崩溃转储".localized
        case .appLeftovers: return "已卸载软件残留".localized
        case .trash: return "废纸篓已删除文件".localized
        }
    }

    public var iconName: String {
        switch self {
        case .userCaches: return "externaldrive.badge.timemachine"
        case .appCaches: return "app.badge.checkmark"
        case .devCaches: return "hammer.fill"
        case .systemLogs: return "doc.text.magnifyingglass"
        case .appLeftovers: return "shippingbox.and.arrow.backward"
        case .trash: return "trash.fill"
        }
    }

    public var description: String {
        switch self {
        case .userCaches: return "包含通用用户缓存 (~/Library/Caches)、网络临时缓存等".localized
        case .appCaches: return "各类常用软件、浏览器（Chrome、Safari 等）本地缓存".localized
        case .devCaches: return "Xcode DerivedData、CocoaPods、Cargo、Gradle、npm 依赖缓存".localized
        case .systemLogs: return "诊断报告、ASL 日志、已归档崩溃日志文件".localized
        case .appLeftovers: return "原应用已被删除，但残留于 Application Support 或 Preferences 的孤儿目录".localized
        case .trash: return "当前用户废纸篓内待清空的内容".localized
        }
    }
}

public struct CleanItem: Identifiable {
    public let id: UUID
    private let nameKey: String
    public let category: CleanCategoryType
    public let path: String
    public var sizeInBytes: Int64
    public var isSelected: Bool
    private let itemDescriptionKey: String

    public var name: String {
        nameKey.localized
    }

    public var itemDescription: String {
        itemDescriptionKey.localized
    }

    public init(
        id: UUID = UUID(),
        name: String,
        category: CleanCategoryType,
        path: String,
        sizeInBytes: Int64,
        isSelected: Bool = true,
        itemDescription: String = ""
    ) {
        self.id = id
        self.nameKey = name
        self.category = category
        self.path = path
        self.sizeInBytes = sizeInBytes
        self.isSelected = isSelected
        self.itemDescriptionKey = itemDescription
    }

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeInBytes, countStyle: .file)
    }
}

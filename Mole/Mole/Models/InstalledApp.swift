//
//  InstalledApp.swift
//  Mole
//

import AppKit
import Foundation

public enum RemnantType: String, CaseIterable, Identifiable {
    case appSupport = "Application Support"
    case caches = "Caches"
    case preferences = "Preferences"
    case containers = "Containers"
    case savedState = "Saved State"
    case logs = "Logs"
    case launchAgents = "Launch Agents"
    case webkit = "WebKit"
    case other = "Other"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .appSupport: return "folder.badge.gearshape"
        case .caches: return "bolt.shield"
        case .preferences: return "slider.horizontal.3"
        case .containers: return "archivebox"
        case .savedState: return "clock.arrow.circlepath"
        case .logs: return "doc.text"
        case .launchAgents: return "gear.badge"
        case .webkit: return "globe"
        case .other: return "folder"
        }
    }
}

public struct AppRemnantItem: Identifiable, Hashable {
    public let id: UUID
    public let path: String
    public let type: RemnantType
    public let sizeInBytes: Int64
    public var isSelected: Bool

    public init(
        id: UUID = UUID(),
        path: String,
        type: RemnantType,
        sizeInBytes: Int64,
        isSelected: Bool = true
    ) {
        self.id = id
        self.path = path
        self.type = type
        self.sizeInBytes = sizeInBytes
        self.isSelected = isSelected
    }

    public static func == (lhs: AppRemnantItem, rhs: AppRemnantItem) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeInBytes, countStyle: .file)
    }

    public var name: String {
        (path as NSString).lastPathComponent
    }
}

public struct InstalledApp: Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let bundleIdentifier: String?
    public let version: String?
    public let path: String
    public var appSizeInBytes: Int64
    public let lastUsedDate: Date?
    public var remnants: [AppRemnantItem]
    public var isSelected: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String?,
        version: String?,
        path: String,
        appSizeInBytes: Int64,
        lastUsedDate: Date?,
        remnants: [AppRemnantItem] = [],
        isSelected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.path = path
        self.appSizeInBytes = appSizeInBytes
        self.lastUsedDate = lastUsedDate
        self.remnants = remnants
        self.isSelected = isSelected
    }

    public static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public var totalSizeInBytes: Int64 {
        appSizeInBytes + remnants.reduce(0) { $0 + $1.sizeInBytes }
    }

    public var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSizeInBytes, countStyle: .file)
    }

    public var formattedAppSize: String {
        ByteCountFormatter.string(fromByteCount: appSizeInBytes, countStyle: .file)
    }

    public var icon: NSImage {
        NSWorkspace.shared.icon(forFile: path)
    }
}

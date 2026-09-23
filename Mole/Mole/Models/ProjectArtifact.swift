//
//  ProjectArtifact.swift
//  Mole
//

import Foundation

public enum ArtifactCategory: String, CaseIterable, Identifiable {
    case nodeModules = "Node.js (node_modules)"
    case xcode = "Xcode (DerivedData / .build)"
    case cocoaPods = "CocoaPods (Pods)"
    case rust = "Rust / Java (target)"
    case gradle = "Gradle (.gradle)"
    case pythonVenv = "Python (.venv / venv)"
    case webBuild = "Web Dist (.next / dist)"
    case other = "Other Artifacts"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .nodeModules: return "shippingbox"
        case .xcode: return "hammer"
        case .cocoaPods: return "cube.box"
        case .rust: return "gearshape.2"
        case .gradle: return "leaf"
        case .pythonVenv: return "terminal"
        case .webBuild: return "globe"
        case .other: return "folder"
        }
    }
}

public struct ProjectArtifactItem: Identifiable, Sendable {
    public let id: UUID
    public let projectName: String
    public let artifactPath: String
    public let category: ArtifactCategory
    public let sizeInBytes: Int64
    public var isSelected: Bool

    public nonisolated init(
        id: UUID = UUID(),
        projectName: String,
        artifactPath: String,
        category: ArtifactCategory,
        sizeInBytes: Int64,
        isSelected: Bool = true
    ) {
        self.id = id
        self.projectName = projectName
        self.artifactPath = artifactPath
        self.category = category
        self.sizeInBytes = sizeInBytes
        self.isSelected = isSelected
    }

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeInBytes, countStyle: .file)
    }
}

public struct InstallerItem: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let path: String
    public let sizeInBytes: Int64
    public let modificationDate: Date?
    public var isSelected: Bool

    public nonisolated init(
        id: UUID = UUID(),
        name: String,
        path: String,
        sizeInBytes: Int64,
        modificationDate: Date?,
        isSelected: Bool = true
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.sizeInBytes = sizeInBytes
        self.modificationDate = modificationDate
        self.isSelected = isSelected
    }

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeInBytes, countStyle: .file)
    }
}

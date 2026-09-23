//
//  DiskAnalysis.swift
//  Mole
//

import Foundation

public struct DiskAnalysisResult: Codable {
    public let path: String
    public let overview: Bool?
    public let entries: [DiskEntryItem]
    public let largeFiles: [DiskLargeFileItem]?
    public let totalSize: Int64
    public let totalFiles: Int64?

    enum CodingKeys: String, CodingKey {
        case path
        case overview
        case entries
        case largeFiles = "large_files"
        case totalSize = "total_size"
        case totalFiles = "total_files"
    }
}

public struct DiskEntryItem: Codable, Identifiable {
    public var id: String { path }
    public let name: String
    public let path: String
    public let size: Int64
    public let isDir: Bool
    public let cleanable: Bool?
    public let lastAccess: String?

    enum CodingKeys: String, CodingKey {
        case name
        case path
        case size
        case isDir = "is_dir"
        case cleanable
        case lastAccess = "last_access"
    }

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

public struct DiskLargeFileItem: Codable, Identifiable {
    public var id: String { path }
    public let name: String
    public let path: String
    public let size: Int64

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

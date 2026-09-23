//
//  PermissionManager.swift
//  Mole
//
//  Created by Kehong-IOS-Dev01 on 2026/9/23.
//

import AppKit
import Combine
import Foundation

@MainActor
public final class PermissionManager: ObservableObject {
    public static let shared = PermissionManager()

    @Published public private(set) var hasFullDiskAccess: Bool = false

    private init() {
        checkPermission()
        // Re-check automatically whenever app becomes active
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkPermission()
        }
    }

    /// Check if Full Disk Access / All Folders access is granted
    public func checkPermission() {
        // Test protected TCC directories that require Full Disk Access on macOS
        let testPaths = [
            NSHomeDirectory() + "/Library/Safari",
            NSHomeDirectory() + "/Library/Suggestions",
            NSHomeDirectory() + "/Library/Mail",
            "/Library/Application Support/com.apple.TCC"
        ]

        for path in testPaths {
            if FileManager.default.isReadableFile(atPath: path) {
                hasFullDiskAccess = true
                return
            }
            if let entries = try? FileManager.default.contentsOfDirectory(atPath: path), !entries.isEmpty {
                hasFullDiskAccess = true
                return
            }
        }

        hasFullDiskAccess = false
    }

    /// Directly open macOS System Settings to Full Disk Access (Privacy_AllFiles)
    public func openFullDiskAccessSettings() {
        // Probe protected path once so macOS registers Mole in the TCC Full Disk Access list
        _ = try? FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Library/Safari")

        // Open System Settings -> Privacy & Security -> Full Disk Access
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Reveal the Mole application bundle in Finder so the user can drag it into System Settings if needed
    public func revealAppInFinder() {
        let bundleURL = Bundle.main.bundleURL
        NSWorkspace.shared.activateFileViewerSelecting([bundleURL])
    }
}

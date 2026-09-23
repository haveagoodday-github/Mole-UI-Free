//
//  MoleProcessRunner.swift
//  Mole
//

import Combine
import Foundation

public final class MoleProcessRunner: ObservableObject {
    public static let shared = MoleProcessRunner()

    @Published public var logEntries: [String] = []
    @Published public var isRunningCommand: Bool = false

    private init() {}

    /// Resolve the root path of the bundled or local MoleCore
    public func resolveMoleCorePath() -> String? {
        let fileManager = FileManager.default

        // 1. Check in Bundle.main (MoleCore.bundle or resourcePath)
        if let bundleUrl = Bundle.main.url(forResource: "MoleCore", withExtension: "bundle") {
            let bundlePath = bundleUrl.path
            if fileManager.fileExists(atPath: (bundlePath as NSString).appendingPathComponent("bin/clean.sh")) {
                return bundlePath
            }
        }
        if let resourcePath = Bundle.main.resourcePath {
            let bundledPath = (resourcePath as NSString).appendingPathComponent("MoleCore.bundle")
            if fileManager.fileExists(atPath: (bundledPath as NSString).appendingPathComponent("bin/clean.sh")) {
                return bundledPath
            }
        }

        // 2. Check in Mole/Mole/Resources/MoleCore.bundle (during local Xcode development)
        let localDevPath = "/Users/kehong01/Downloads/Mole-for-mac/Mole/Mole/Resources/MoleCore.bundle"
        if fileManager.fileExists(atPath: (localDevPath as NSString).appendingPathComponent("bin/clean.sh")) {
            return localDevPath
        }

        // 3. Fallback to Mole-main
        let fallbackPath = "/Users/kehong01/Downloads/Mole-for-mac/Mole-main"
        if fileManager.fileExists(atPath: (fallbackPath as NSString).appendingPathComponent("bin/clean.sh")) {
            return fallbackPath
        }

        return nil
    }

    /// Resolve path for a specific binary or script inside MoleCore
    public func resolveExecutable(named name: String) -> String? {
        guard let corePath = resolveMoleCorePath() else { return nil }
        let binPath = (corePath as NSString).appendingPathComponent("bin/\(name)")
        if FileManager.default.fileExists(atPath: binPath) {
            if !FileManager.default.isExecutableFile(atPath: binPath) {
                try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binPath)
            }
            return binPath
        }
        return nil
    }

    private var activeCommandsCount: Int = 0

    /// Append a message to the shared log stream
    @MainActor
    public func appendLog(_ message: String) {
        logEntries.append(message)
        if logEntries.count > 1000 {
            logEntries.removeFirst(100)
        }
    }

    /// Clear logs
    @MainActor
    public func clearLogs() {
        logEntries.removeAll()
    }

    /// Execute a shell script or command asynchronously, streaming output in real-time
    @discardableResult
    public func runShellCommand(
        _ command: String,
        currentDirectory: String? = nil,
        silent: Bool = false,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) async -> (exitCode: Int32, output: String) {
        if !silent {
            await MainActor.run {
                self.activeCommandsCount += 1
                self.isRunningCommand = true
                self.appendLog("❯ \(command)")
            }
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]

        if let cwd = currentDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: cwd)
        } else if let corePath = resolveMoleCorePath() {
            process.currentDirectoryURL = URL(fileURLWithPath: corePath)
        }

        // Enrich PATH with standard Homebrew and macOS binary paths
        var env = ProcessInfo.processInfo.environment
        let standardPath = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        if let existing = env["PATH"] {
            env["PATH"] = "\(standardPath):\(existing)"
        } else {
            env["PATH"] = standardPath
        }
        env["LC_ALL"] = "C"
        env["LANG"] = "C"
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let accumulatedOutput = LockedAccumulator()

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let string = String(data: data, encoding: .utf8) {
                accumulatedOutput.append(string)
                if !silent {
                    DispatchQueue.main.async {
                        self.appendLog(string.trimmingCharacters(in: .newlines))
                    }
                }
                onOutput?(string)
            }
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let string = String(data: data, encoding: .utf8) {
                accumulatedOutput.append(string)
                if !silent {
                    DispatchQueue.main.async {
                        self.appendLog("[stderr] \(string.trimmingCharacters(in: .newlines))")
                    }
                }
                onOutput?(string)
            }
        }

        let exitCode: Int32 = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                process.terminationHandler = { proc in
                    continuation.resume(returning: proc.terminationStatus)
                }
                do {
                    try process.run()
                } catch {
                    if !silent {
                        Task { @MainActor in
                            self.appendLog("❌ Failed to start process: \(error.localizedDescription)")
                        }
                    }
                    continuation.resume(returning: -1)
                }
            }
        } onCancel: {
            if process.isRunning {
                process.terminate()
            }
        }

        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        // Drain any remaining bytes from pipes
        if let remainingOut = try? stdoutPipe.fileHandleForReading.readToEnd(),
           let str = String(data: remainingOut, encoding: .utf8), !str.isEmpty {
            accumulatedOutput.append(str)
        }
        if let remainingErr = try? stderrPipe.fileHandleForReading.readToEnd(),
           let str = String(data: remainingErr, encoding: .utf8), !str.isEmpty {
            accumulatedOutput.append(str)
        }

        if !silent {
            await MainActor.run {
                self.activeCommandsCount = max(0, self.activeCommandsCount - 1)
                self.isRunningCommand = self.activeCommandsCount > 0
            }
        }

        return (exitCode, accumulatedOutput.value)
    }
}

private final class LockedAccumulator: @unchecked Sendable {
    private var storage = ""
    private let lock = NSLock()

    func append(_ string: String) {
        lock.lock()
        storage.append(string)
        lock.unlock()
    }

    var value: String {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}

//
//  SystemStatus.swift
//  Mole
//

import Foundation

public struct SystemStatusSnapshot: Codable {
    public let collectedAt: String?
    public let host: String?
    public let platform: String?
    public let uptime: String?
    public let procs: Int?
    public let hardware: HardwareInfo?
    public let healthScore: Int?
    public let healthScoreMsg: String?
    public let cpu: CPUInfo?
    public let memory: MemoryInfo?
    public let disks: [DiskInfo]?
    public let network: [NetworkInterfaceInfo]?
    public let topProcesses: [ProcessInfoItem]?
    public let thermal: ThermalInfo?
    public let bluetooth: [BluetoothDeviceInfo]?

    enum CodingKeys: String, CodingKey {
        case collectedAt = "collected_at"
        case host
        case platform
        case uptime
        case procs
        case hardware
        case healthScore = "health_score"
        case healthScoreMsg = "health_score_msg"
        case cpu
        case memory
        case disks
        case network
        case topProcesses = "top_processes"
        case thermal
        case bluetooth
    }
}

public struct HardwareInfo: Codable {
    public let model: String?
    public let cpuModel: String?
    public let totalRam: String?
    public let diskSize: String?
    public let osVersion: String?
    public let refreshRate: String?

    enum CodingKeys: String, CodingKey {
        case model
        case cpuModel = "cpu_model"
        case totalRam = "total_ram"
        case diskSize = "disk_size"
        case osVersion = "os_version"
        case refreshRate = "refresh_rate"
    }
}

public struct CPUInfo: Codable {
    public let usage: Double?
    public let perCore: [Double]?
    public let load1: Double?
    public let load5: Double?
    public let load15: Double?
    public let coreCount: Int?
    public let logicalCpu: Int?
    public let pCoreCount: Int?
    public let eCoreCount: Int?

    enum CodingKeys: String, CodingKey {
        case usage
        case perCore = "per_core"
        case load1
        case load5
        case load15
        case coreCount = "core_count"
        case logicalCpu = "logical_cpu"
        case pCoreCount = "p_core_count"
        case eCoreCount = "e_core_count"
    }
}

public struct MemoryInfo: Codable {
    public let used: Int64?
    public let total: Int64?
    public let available: Int64?
    public let usedPercent: Double?
    public let swapUsed: Int64?
    public let swapTotal: Int64?
    public let cached: Int64?

    enum CodingKeys: String, CodingKey {
        case used
        case total
        case available
        case usedPercent = "used_percent"
        case swapUsed = "swap_used"
        case swapTotal = "swap_total"
        case cached
    }
}

public struct DiskInfo: Codable, Identifiable {
    public var id: String { mount ?? device ?? UUID().uuidString }
    public let mount: String?
    public let device: String?
    public let used: Int64?
    public let total: Int64?
    public let usedPercent: Double?
    public let fstype: String?
    public let purgeable: Int64?

    enum CodingKeys: String, CodingKey {
        case mount
        case device
        case used
        case total
        case usedPercent = "used_percent"
        case fstype
        case purgeable
    }
}

public struct NetworkInterfaceInfo: Codable, Identifiable {
    public var id: String { name ?? UUID().uuidString }
    public let name: String?
    public let rxRateMbs: Double?
    public let txRateMbs: Double?
    public let ip: String?

    enum CodingKeys: String, CodingKey {
        case name
        case rxRateMbs = "rx_rate_mbs"
        case txRateMbs = "tx_rate_mbs"
        case ip
    }
}

public struct ProcessInfoItem: Codable, Identifiable {
    public var id: Int { pid }
    public let pid: Int
    public let ppid: Int?
    public let name: String
    public let command: String?
    public let cpu: Double?
    public let memory: Double?
    public let memoryBytes: Int64?

    enum CodingKeys: String, CodingKey {
        case pid
        case ppid
        case name
        case command
        case cpu
        case memory
        case memoryBytes = "memory_bytes"
    }
}

public struct ThermalInfo: Codable {
    public let cpuTemp: Double?
    public let gpuTemp: Double?
    public let fanSpeed: Double?
    public let systemPower: Double?

    enum CodingKeys: String, CodingKey {
        case cpuTemp = "cpu_temp"
        case gpuTemp = "gpu_temp"
        case fanSpeed = "fan_speed"
        case systemPower = "system_power"
    }
}

public struct BluetoothDeviceInfo: Codable, Identifiable {
    public var id: String { name }
    public let name: String
    public let connected: Bool
    public let battery: String?
}

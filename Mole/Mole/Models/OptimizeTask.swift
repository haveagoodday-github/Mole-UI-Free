//
//  OptimizeTask.swift
//  Mole
//

import Foundation

public enum TaskExecutionState: Equatable {
    case idle
    case running
    case completed(message: String)
    case failed(message: String)
}

public struct OptimizeTask: Identifiable {
    public let id: String
    private let titleKey: String
    private let subtitleKey: String
    public let iconName: String
    public var isSelected: Bool
    public var state: TaskExecutionState
    public let command: String

    public var title: String {
        titleKey.localized
    }

    public var subtitle: String {
        subtitleKey.localized
    }

    public init(
        id: String,
        title: String,
        subtitle: String,
        iconName: String,
        command: String,
        isSelected: Bool = true,
        state: TaskExecutionState = .idle
    ) {
        self.id = id
        self.titleKey = title
        self.subtitleKey = subtitle
        self.iconName = iconName
        self.command = command
        self.isSelected = isSelected
        self.state = state
    }

    public static var defaultTasks: [OptimizeTask] {
        [
            OptimizeTask(
                id: "purge_ram",
                title: "释放非活跃内存 (Purge RAM)",
                subtitle: "通知 macOS 系统回收非活跃/未使用的内存缓存，使可用内存立刻回升",
                iconName: "memorychip",
                command: "purge"
            ),
            OptimizeTask(
                id: "flush_dns",
                title: "刷新系统 DNS 缓存",
                subtitle: "清除陈旧或解析失败的 DNS 记录，修复网络连接与域名解析异常",
                iconName: "network",
                command: "dscacheutil -flushcache; killall -HUP mDNSResponder 2>/dev/null || true"
            ),
            OptimizeTask(
                id: "rebuild_spotlight",
                title: "重新索引 Spotlight 聚焦搜索",
                subtitle: "刷新并重建系统文件搜索索引，解决文件搜索不到或占用高的问题",
                iconName: "magnifyingglass",
                command: "mdutil -E / 2>/dev/null || true"
            ),
            OptimizeTask(
                id: "rebuild_launchservices",
                title: "重建打开方式与 LaunchServices 数据库",
                subtitle: "修复右键“打开方式”列表中的重复应用项以及已删除软件的幽灵图标",
                iconName: "arrow.triangle.2.circlepath",
                command: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user 2>/dev/null || true"
            ),
            OptimizeTask(
                id: "clean_font_cache",
                title: "清除系统字体缓存",
                subtitle: "重置 ATS 字体服务器数据库，修复文字显示乱码或字体缺失问题",
                iconName: "textformat",
                command: "atsutil databases -removeUser 2>/dev/null || true"
            ),
            OptimizeTask(
                id: "vacuum_sqlite",
                title: "整理压缩 SQLite 数据库",
                subtitle: "清理并压缩用户目录下的 SQLite 数据库文件碎片，提高读写性能",
                iconName: "cylinder.split.1x2",
                command: "find \"$HOME/Library\" -name \"*.db\" -o -name \"*.sqlite\" 2>/dev/null | head -n 30 | while read -r f; do sqlite3 \"$f\" \"VACUUM;\" 2>/dev/null || true; done"
            ),
            OptimizeTask(
                id: "clean_broken_symlinks",
                title: "清理失效的快捷软链接",
                subtitle: "扫描并安全移除指向不存在目标文件的死链接与悬空软链接",
                iconName: "link.badge.plus",
                command: "find \"$HOME\" -maxdepth 3 -type l -exec test ! -e {} \\; -print 2>/dev/null | head -n 50 | while read -r l; do rm -f \"$l\" 2>/dev/null || true; done"
            ),
            OptimizeTask(
                id: "restart_ui_services",
                title: "重启系统界面核心服务",
                subtitle: "优雅重启 Dock、Finder 与状态栏，清理由于长期开机导致的界面卡顿",
                iconName: "sparkles",
                command: "killall Dock Finder SystemUIServer 2>/dev/null || true"
            )
        ]
    }
}

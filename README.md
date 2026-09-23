# Mole for Mac (GUI Edition)

<p align="center">
  <em>🐹 现代化、高颜值的 macOS 原生系统清理、磁盘透视与维护调优桌面应用</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2012%2B-blue.svg?style=flat-square&logo=apple" alt="Platform" />
  <img src="https://img.shields.io/badge/Language-SwiftUI%20%7C%20Go%20%7C%20Shell-orange.svg?style=flat-square" alt="Language" />
  <img src="https://img.shields.io/badge/License-GPL_v3-green.svg?style=flat-square" alt="License" />
  <img src="https://img.shields.io/badge/Core%20Engine-tw93%2Fmole-purple.svg?style=flat-square" alt="Core Engine" />
</p>

---

## 💖 开源致敬与免责声明 (Attribution & Disclaimer)

本项目属于基于 GitHub 优秀开源成果二次开发的 macOS 原生图形界面（GUI）客户端。

- **核心技术致敬**：本项目的底层清理脚本、磁盘分析与状态监测等核心逻辑深度整合并致敬了开源项目 **[tw93/mole](https://github.com/tw93/mole)**。
- **原作者鸣谢**：衷心感谢原作者 **[Tw93 (@HiTw93)](https://github.com/tw93)** 以及为该项目贡献代码的开源开发者们，是他们出色的 CLI 设计与底层工具沉淀为本项目提供了坚实基石！
- **开源协议**：本项目严格遵循 **GNU General Public License v3.0 (GPL-3.0)** 协议保持开源。
- **独立声明与商标合规说明**：
  1. 本项目为开源社区爱好者自主研发的独立图形化桌面端，采用纯原生 SwiftUI 打造。
  2. 根据原项目的 [TRADEMARK.md](Mole-main/TRADEMARK.md) 规定，本项目与 Tw93 官方运营的专有商业软件 **[Mole for Mac (mole.fit)](https://mole.fit)** 无从属、赞助或商业代理关系。
  3. 软件中保留原项目的完整版权声明与许可证；用户与二次开发者在分发或商业化衍生物时，请遵守 GPL-3.0 协议及原作者商标政策。

---

## ✨ 功能特性 (Features)

| 功能模块 | 对应技术 | 说明 |
| :--- | :--- | :--- |
| **📊 系统仪表盘**<br>`Dashboard` | `status-go` | 实时监测 CPU 占用、GPU、统一内存水位、网络上下行速度与磁盘健康。 |
| **🧹 深度系统清理**<br>`Clean` | Native + Shell | 智能扫描用户缓存、浏览器缓存（Safari/Chrome/Edge）、开发环境缓存（Xcode DerivedData、CocoaPods、Cargo、Gradle、npm、Homebrew）、系统日志及废纸篓。 |
| **🗑️ 应用彻底卸载**<br>`Uninstall` | AppKit + Shell | 一键分析已安装软件及其在 `~/Library`、`Application Support`、`LaunchAgents` 等各级目录中的深层配置残留，实现真正无痕卸载。 |
| **🔍 磁盘空间透视**<br>`Analyze` | `analyze-go` | 类似 DaisyDisk 的直观层级饼图与树状透视，快速定位占用数 GB 以上的深层隐藏大文件。 |
| **⚡ 系统维护调优**<br>`Optimize` | macOS System Tools | 一键刷新 DNS 缓存、重建 LaunchServices 启动映射表、重新索引 Spotlight 聚焦搜索、清理剪贴板与闲置内存。 |
| **🛠️ 工程构建清理**<br>`Purge` | Dev Tools | 专为开发者量身打造，批量扫描并一键收割项目中的 `node_modules`、`DerivedData`、`target`、`build`、`.gradle` 等膨胀产物。 |
| **📦 安装镜像清理**<br>`Installer` | Disk Image Engine | 自动检索硬盘各处闲置遗忘的 `.dmg`、`.pkg`、`.iso` 安装包并支持一键清理。 |
| **💻 终端实时日志**<br>`Terminal Logs` | `MoleProcessRunner` | 界面底端配备实时日志抽屉，所有底层命令执行进度、参数输出与日志全程透明可查。 |

---

## 🏗️ 架构与技术栈 (Architecture)

- **前端界面 (Presentation)**：
  - 基于 **SwiftUI 5 / AppKit** 构建，支持 macOS 12+ 经典与最新交互范式。
  - 采用 `NavigationSplitView` 原生双栏/三栏布局与 SF Symbols 统一视觉语言。
  - 内置 `LanguageManager`，支持简体中文、繁体中文、英文热切换，无须重启应用。
- **业务引擎 (Domain & Services)**：
  - `CleanEngine`：并发计算目录体积与异步清理。
  - `UninstallEngine`：深度关联 App 签名与残留文件寻址。
  - `DiskAnalyzerEngine`：与 `analyze-go` 二进制交互获取结构化 JSON 磁盘树。
  - `StatusMonitorService`：定期轮询硬件性能与温度健康。
- **核心通信层 (Infrastructure)**：
  - `MoleProcessRunner`：封装异步进程管道与实时输出流，支持 Bundle 资源定位与本地开发环境自动 fallback。

---

## 🚀 编译与运行 (Build & Run)

### 前置要求
- **macOS**：12.0 或更高版本
- **Xcode**：15.0 或更高版本 (支持 macOS SDK)
- **Architecture**：Apple Silicon (M 系列芯片) 及 Intel 芯片原生通用二进制

### 快速上手
1. 克隆或打开本项目目录：
   ```bash
   cd Mole
   open Mole.xcodeproj
   ```
2. 在 Xcode 顶部选择 **Mole** Scheme 以及运行目标为 **My Mac**。
3. 按下 `Cmd + R` 即可编译并在本地运行原生客户端。

---

## 🤝 致谢 (Acknowledgements)

- **[tw93/mole](https://github.com/tw93/mole)**：感谢 Tw93 打造的高效优雅的 Mac 终端优化利器。
- **SwiftUI & Apple Open Source**：为桌面端带来卓越流畅的原生体验。

---

## 📜 许可证 (License)

本项目采用 [GNU General Public License v3.0 (GPL-3.0)](LICENSE) 协议开源。
更多信息请参阅原项目许可证及相关协议条款。

# PCL.Mac 开发文档

> 本文档基于 2025-10-01 前的 PCL.Mac 代码阅读及结构整理，内容可能因代码更新而不完整。更多文件和内容请[在 GitHub 代码仓库中检索](https://github.com/PCL-Community/PCL.Mac/search)。

## 项目简介

PCL.Mac 是基于 SwiftUI 框架重写的 Minecraft 启动器 Plain Craft Launcher 的 macOS 平台非官方衍生版（**不是点云库！**）。

- 支持 Minecraft 启动、mod 管理等功能。
- UI 接近原版，体验贴合 macOS。
- 2025 年 10 月 1 日发布第一个正式版。

---

## 快速开始

### 1. 获取源码

```shell
git clone https://github.com/PCL-Community/PCL.Mac.git
cd PCL.Mac
```

### 2. 编译前准备

如遇到无法编译（缺少 Secrets.xcconfig），请**在仓库根目录新建空白文件**：

```shell
touch Secrets.xcconfig
```

### 3. 使用 Xcode 打开并运行

- 推荐 Xcode 16+，macOS 14+。
- 直接用 Xcode 打开 `PCL.Mac.xcodeproj`，选择 PCL.Mac 目标运行。

---

## 目录结构

```
PCL.Mac/
  ├── App/                # App 逻辑（@main、AppDelegate 等）
  ├── Core/               # 启动器核心模块（如日志、网络、下载等）
  ├── Managers/           # 各种运行时管理器
  ├── Shared/
  │    ├── Components/    # 复用 SwiftUI 控件（新控件放这里，命名对齐原版 Plain Craft Launcher）
  │    └── Storage/       # 本地存储与设置
  ├── ContentView.swift   # 主视图
  ├── Info.plist
  └── Secrets.swift       # 编译时替换的敏感数据
```

> 说明：新控件请放到 `PCL.Mac/Shared/Components/`，新逻辑放到 `PCL.Mac.Core/`，如需与主工程交互，**除日志外尽量不要直接调用 PCL.Mac 层的 API（如 PopupManager），推荐通过 Result 或回调等方式解耦**。

---

## 命名与提交规范

### 命名规范

- 采用标准 Swift 命名习惯。
- 缩写全大写（如 URL、ID）。
- 新控件名与 Plain Craft Launcher 对齐。

### 提交信息规范

- 采用如 `feat: xxx`、`chore`、`perf`、`refactor`、`docs` 等前缀。
- 可加括号说明作用点，如 `feat(popup): 新增弹窗动画`。
- 文档改动请额外加 `[skip ci]`。

---

## 主要模块与 API 说明

### 1. 日志系统（LogManager）

文件: `PCL.Mac.Core/LogManager.swift`

**用途：** 统一输出、存储日志，支持 INFO、WARN、ERROR、DEBUG 级别。

**API:**
```swift
log(_ message: Any)
warn(_ message: Any)
err(_ message: Any)
debug(_ message: Any)
```
- 可选参数：`file`, `line`，自动补全调用位置。
- 日志内容异步写入，支持查看开发模式下的日志行。
- 支持日志清理与保存。

### 2. 下载（Aria2Manager）

文件: `PCL.Mac.Core/Aria2/Aria2Manager.swift`

**用途：** 基于 Aria2 进行多线程高速下载。

**常用 API：**
```swift
// 单个文件下载
func download(url: URL, destination: URL, progress: ((Double, Int) -> Void)? = nil) async throws

// 带备用 URL 的单文件下载
func download(urls: [URL], destination: URL, progress: ((Double, Int) -> Void)? = nil) async throws
```
- `progress` 回调参数为 (进度百分比, 当前速度)
- 下载过程中自动检测 Aria2 进程状态和错误。

### 3. AppSettings（应用设置）

文件: `PCL.Mac/Shared/Storage/AppSettings.swift`

**用途：** 保存/同步用户设置、主题、Minecraft 路径等。

**主要字段举例：**
```swift
@AppStorage("showPclMacPopup") public var showPclMacPopup: Bool
@CodableAppStorage("themeId") public var themeId: String
@CodableAppStorage("colorScheme") public var colorScheme: ColorSchemeOption
@CodableAppStorage("currentMinecraftDirectory") public var currentMinecraftDirectory: MinecraftDirectory?
@AppStorage("hasMicrosoftAccount") public var hasMicrosoftAccount: Bool
```
**添加设置项方式：**
- 使用 `@AppStorage` 或 `@CodableAppStorage` 属性包装器，自动同步到 UserDefaults。

### 4. 各类 Manager 简述

#### DataManager

- 负责全局数据、主界面同步（如 Java 版本、左侧标签页、版本清单）。
- 单例 `DataManager.shared`。
- 通过 `refreshVersionManifest()` 拉取/缓存 Minecraft 版本清单。

#### PopupManager

- 统一弹窗管理，支持同步与异步弹窗显示，自动管理弹窗状态。
- 推荐通过 `showAsync(_:)` 获得弹窗按钮选择结果。

#### HintManager

- 与原版的 Hint 一致，自动消失。
- 用法：`hint("提示内容", .info)`。

#### StateManager

- 持有页面/卡片等组件的临时状态，主用于页面切换数据缓存。

### 5. Architecture（架构及架构检测）

文件: `PCL.Mac.Core/Architecture.swift`

**用途：** 可执行文件架构检测与系统架构获取。

**API**
```swift
static func getArchOfFile(_ executableURL: URL) -> Architecture
static var system: Architecture
```

---

## 新增功能/控件开发建议

- **新控件放入** `PCL.Mac/Shared/Components/`，命名与 Plain Craft Launcher 保持一致。
- **新逻辑放入** `PCL.Mac.Core/`，如需与 UI 层通信，优先使用回调、Result 或通知解耦。
- **如需持久化设置**，请在 `AppSettings` 中添加对应字段，使用属性包装器自动存储。

---

## 发布与版本

- 本项目计划 2025 年 10 月 1 日发布第一个正式版。
- 变更记录请见 GitHub Releases 或 Commit 历史。

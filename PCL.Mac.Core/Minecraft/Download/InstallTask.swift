//
//  InstallTask.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/7.
//

import Foundation

public class InstallTask: ObservableObject, Identifiable, Hashable, Equatable {
    @Published public var stage: InstallStage = .before
    @Published public var remainingFiles: Int = -1
    @Published public var totalFiles: Int = -1
    @Published public var currentStagePercentage: Double = 0
    
    public let id: UUID = UUID()
    public var callback: (() -> Void)? = nil
    
    public static func == (lhs: InstallTask, rhs: InstallTask) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public func start() { }
    public func getInstallStates() -> [InstallStage : InstallState] { [:] }
    public func getTitle() -> String { "" }
    public func onComplete(_ callback: @escaping () -> Void) {
        self.callback = callback
    }
    
    public func updateStage(_ stage: InstallStage) {
        debug("切换阶段: \(stage.getDisplayName())")
        DispatchQueue.main.async {
            self.stage = stage
            self.currentStagePercentage = 0
        }
    }
    
    public func getProgress() -> Double {
        Double(totalFiles - remainingFiles) / Double(totalFiles)
    }
    
    public func complete() {
        log("下载任务完成")
        self.updateStage(.end)
        DispatchQueue.main.async {
            DataManager.shared.inprogressInstallTasks = nil
            if case .installing(_) = DataManager.shared.router.getLast() {
                DataManager.shared.router.removeLast()
            }
            self.callback?()
        }
    }
    
    public func completeOneFile() {
        DispatchQueue.main.async {
            self.remainingFiles -= 1
        }
    }
}

public class InstallTasks: ObservableObject, Identifiable, Hashable, Equatable {
    @Published public var tasks: [String : InstallTask]
    
    public let id: UUID = .init()
    public static func == (lhs: InstallTasks, rhs: InstallTasks) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(tasks)
    }
    
    public var totalFiles: Int {
        var totalFiles = 0
        tasks.values.forEach { totalFiles += $0.totalFiles }
        return totalFiles
    }
    
    public var remainingFiles: Int {
        var remainingFiles = 0
        tasks.values.forEach { remainingFiles += $0.remainingFiles }
        return remainingFiles
    }
    
    public func getProgress() -> Double {
        Double(totalFiles - remainingFiles) / Double(totalFiles)
    }
    
    public func getTasks() -> [InstallTask] {
        let order = ["minecraft", "fabric", "customFile"]
        return order.compactMap { tasks[$0] }
    }
    
    public func addTask(key: String, task: InstallTask) {
        tasks[key] = task
    }
    
    init(_ tasks: [String : InstallTask]) {
        self.tasks = tasks
    }
    
    public static func single(_ task: InstallTask, key: String = "minecraft") -> InstallTasks { .init([key : task]) }
    
    public static func empty() -> InstallTasks { .init([:]) }
}

// MARK: - Minecraft 安装任务定义
public class MinecraftInstallTask: InstallTask {
    public var manifest: ClientManifest?
    public var assetIndex: AssetIndex?
    public var name: String
    public var versionUrl: URL { minecraftDirectory.versionsUrl.appending(path: name) }
    public let minecraftVersion: MinecraftVersion
    public let minecraftDirectory: MinecraftDirectory
    public let startTask: (MinecraftInstallTask) async -> Void
    
    public init(minecraftVersion: MinecraftVersion, minecraftDirectory: MinecraftDirectory, name: String, startTask: @escaping (MinecraftInstallTask) async -> Void) {
        self.minecraftVersion = minecraftVersion
        self.minecraftDirectory = minecraftDirectory
        self.name = name
        self.startTask = startTask
    }
    
    public override func start() {
        Task {
            await startTask(self)
            complete()
        }
    }
    
    public override func getInstallStates() -> [InstallStage : InstallState] {
        let allStages: [InstallStage] = [.clientJson, .clientIndex, .clientJar, .clientResources, .clientLibraries, .natives]
        var result: [InstallStage: InstallState] = [:]
        var foundCurrent = false
        for stage in allStages {
            if foundCurrent {
                result[stage] = .waiting
            } else if self.stage == stage {
                result[stage] = .inprogress
                foundCurrent = true
            } else {
                result[stage] = .finished
            }
        }
        return result
    }
    
    public override func getTitle() -> String {
        "\(minecraftVersion.displayName) 安装"
    }
}

// MARK: - Fabric 安装任务定义
public class FabricInstallTask: InstallTask {
    public let loaderVersion: String
    
    init(loaderVersion: String) {
        self.loaderVersion = loaderVersion
    }
    
    public func start(_ task: MinecraftInstallTask) {
        Task {
            await ModLoaderInstaller.installFabric(version: task.minecraftVersion, minecraftDirectory: task.minecraftDirectory, runningDirectory: task.versionUrl, self.loaderVersion)
            callback?()
        }
    }
    
    public override func getInstallStates() -> [InstallStage : InstallState] {
        let allStages: [InstallStage] = [.installFabric]
        var result: [InstallStage: InstallState] = [:]
        var foundCurrent = false
        for stage in allStages {
            if foundCurrent {
                result[stage] = .waiting
            } else if self.stage == stage {
                result[stage] = .inprogress
                foundCurrent = true
            } else {
                result[stage] = .finished
            }
        }
        return result
    }
    
    public override func getTitle() -> String {
        "Fabric \(loaderVersion) 安装"
    }
}

public class CustomFileInstallTask: InstallTask {
    private let url: URL
    private let destination: URL
    private var progress: Double = 0
    
    init(url: URL, destination: URL) {
        self.url = url
        self.destination = destination
        super.init()
        self.totalFiles = 1
        self.remainingFiles = 1
    }
    
    public override func getTitle() -> String {
        "自定义下载：\(destination.lastPathComponent)"
    }
    
    public override func getProgress() -> Double {
        progress
    }
    
    public override func start() {
        Task {
            let downloader = ChunkedDownloader(url: url, destination: destination, chunkCount: 64) { finished, total in
                self.progress = Double(finished) / Double(total)
            }
            await downloader.start()
            complete()
        }
    }
    
    public override func getInstallStates() -> [InstallStage : InstallState] {
        [.customFile: .inprogress]
    }
}

// MARK: - 安装进度定义
public enum InstallStage: Int {
    case before = 0
    case clientJson = 1
    case clientIndex = 2
    case clientJar = 3
    case installFabric = 4
    case clientResources = 5
    case clientLibraries = 6
    case natives = 7
    case end = 8
    case customFile = 1_1_4_5_1_4
    case mods = 1_9_1_9_8_1_0
    
    public func getDisplayName() -> String {
        switch self {
        case .before: "未启动"
        case .clientJson: "下载原版 json 文件"
        case .clientJar: "下载原版 jar 文件"
        case .installFabric: "安装 Fabric"
        case .clientIndex: "下载资源索引文件"
        case .clientResources: "下载散列资源文件"
        case .clientLibraries: "下载依赖项文件"
        case .natives: "下载本地库文件"
        case .customFile: "下载自定义文件"
        case .mods: "下载模组"
        case .end: "结束"
        }
    }
}

// MARK: - 安装进度状态定义
public enum InstallState {
    case waiting, inprogress, finished, failed
    public func getImageName() -> String {
        switch self {
        case .waiting:
            "InstallWaiting"
        case .finished:
            "InstallFinished"
        default:
            "Missingno"
        }
    }
}

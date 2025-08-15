//
//  InstallTask.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/7.
//

import Foundation
import Combine

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
        var progress: Double = 0
        for task in tasks.values {
            progress += task.getProgress()
        }
        return progress / Double(tasks.count)
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
        subscribeToTasks()
    }
    
    private var cancellables: [AnyCancellable] = []
    
    private func subscribeToTasks() {
        cancellables.forEach { $0.cancel() }
        cancellables = []
        for task in tasks.values {
            subscribeToTask(task)
        }
    }

    private func subscribeToTask(_ task: InstallTask) {
        let cancellable = task.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        cancellables.append(cancellable)
    }
    
    public static func single(_ task: InstallTask, key: String = "minecraft") -> InstallTasks { .init([key : task]) }
    
    public static func empty() -> InstallTasks { .init([:]) }
}

// MARK: - Minecraft 安装任务定义
public class MinecraftInstallTask: InstallTask {
    public var manifest: ClientManifest?
    public var assetIndex: AssetIndex?
    public var name: String
    public var versionURL: URL { minecraftDirectory.versionsURL.appending(path: name) }
    public let minecraftVersion: MinecraftVersion
    public let minecraftDirectory: MinecraftDirectory
    public let startTask: (MinecraftInstallTask) async -> Void
    public let architecture: Architecture
    
    public init(minecraftVersion: MinecraftVersion, minecraftDirectory: MinecraftDirectory, name: String, architecture: Architecture = .system, startTask: @escaping (MinecraftInstallTask) async -> Void) {
        self.minecraftVersion = minecraftVersion
        self.minecraftDirectory = minecraftDirectory
        self.name = name
        self.startTask = startTask
        self.architecture = architecture
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
            do {
                let manifestURL = task.versionURL.appending(path: "\(task.name).json")
                try await FabricInstaller.installFabric(version: task.minecraftVersion, minecraftDirectory: task.minecraftDirectory, runningDirectory: task.versionURL, self.loaderVersion)
                task.manifest = try ClientManifest.parse(url: manifestURL, minecraftDirectory: task.minecraftDirectory)
            } catch {
                err("无法安装 Fabric: \(error.localizedDescription)")
            }
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

public class CustomFileDownloadTask: InstallTask {
    private let url: URL
    private let destination: URL
    @Published private var progress: Double = 0
    
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
        currentStagePercentage
    }
    
    public override func start() {
        Task {
            do {
                try await Aria2Manager.shared.download(url: url, destination: destination) { percent, speed in
                    self.currentStagePercentage = percent
                    DataManager.shared.downloadSpeed = Double(speed)
                }
            } catch {
                hint("\(destination.lastPathComponent) 下载失败: \(error.localizedDescription.replacingOccurrences(of: "\n", with: ""))", .critical)
                complete()
                return
            }
            hint("\(destination.lastPathComponent) 下载完成！", .finish)
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
    case customFile = 1000
    case mods = 2000
    case resourcePacks = 2001
    case javaDownload = 3000
    case javaInstall = 3001
    
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
        case .resourcePacks: "下载资源包"
        case .end: "结束"
        case .javaDownload: "下载 Java"
        case .javaInstall: "安装 Java"
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

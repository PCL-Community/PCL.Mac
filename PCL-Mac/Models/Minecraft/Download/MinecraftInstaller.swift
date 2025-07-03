//
//  MinecraftInstallerNew.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/5/31.
//

/**
 *                             _ooOoo_
 *                            o8888888o
 *                            88" . "88
 *                            (| -_- |)
 *                            O\  =  /O
 *                         ____/`---'\____
 *                       .'  \\|     |//  `.
 *                      /  \\|||  :  |||//  \
 *                     /  _||||| -:- |||||-  \
 *                     |   | \\\  -  /// |   |
 *                     | \_|  ''\---/''  |   |
 *                     \  .-\__  `-`  ___/-. /
 *                   ___`. .'  /--.--\  `. . __
 *                ."" '<  `.___\_<|>_/___.'  >'"".
 *               | | :  `- \`.;`\ _ /`;.`/ - ` : | |
 *               \  \ `-.   \_ __\ /__ _/   .-` /  /
 *          ======`-.____`-.___\_____/___.-`____.-'======
 *                             `=---='
 *          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*/

import Foundation

public class MinecraftInstaller {
    private init() {}
    
    // MARK: 下载客户端清单
    private static func downloadClientManifest(_ task: InstallTask) async {
        task.updateStage(.clientJson)
        let minecraftVersion = task.minecraftVersion.displayName
        let clientJsonUrl = task.versionUrl.appending(path: "\(task.name).json")
        await withCheckedContinuation { continuation in
            let downloader = ProgressiveDownloader(
                task: task,
                urls: [URL(string: "https://bmclapi2.bangbang93.com/version/\(minecraftVersion)/json")!],
                destinations: [clientJsonUrl],
                completion: {
                // 解析 JSON
                if let data = try? Data(contentsOf: clientJsonUrl),
                   let manifest: ClientManifest = try? .parse(data, instanceUrl: nil) {
                    task.manifest = manifest
                    ArtifactVersionMapper.map(task.manifest!)
                } else {
                    err("无法解析 JSON")
                }
                continuation.resume()
            })
            downloader.start()
        }
    }
    
    // MARK: 下载客户端本体
    private static func downloadClientJar(_ task: InstallTask, skipIfExists: Bool = false) async {
        task.updateStage(.clientJar)
        let clientJarUrl = task.versionUrl.appending(path: "\(task.name).jar")
        await withCheckedContinuation { continuation in
            let downloader = ProgressiveDownloader(
                task: task,
                urls: [URL(string: "https://bmclapi2.bangbang93.com/version/\(task.minecraftVersion.displayName)/client")!],
                destinations: [clientJarUrl],
                skipIfExists: skipIfExists,
                completion: {
                continuation.resume()
            })
            downloader.start()
        }
    }
    
    // MARK: 下载资源索引
    private static func downloadAssetIndex(_ task: InstallTask) async {
        task.updateStage(.clientIndex)
        let assetIndexUrl: URL = URL(string: task.manifest!.assetIndex.url)!
        let destUrl: URL = task.minecraftDirectory.assetsUrl.appending(component: "indexes").appending(component: "\(task.manifest!.assetIndex.id).json")
        await withCheckedContinuation { continuation in
            let downloader = ProgressiveDownloader(
                task: task,
                urls: [assetIndexUrl],
                destinations: [destUrl],
                skipIfExists: true,
                completion: {
                do {
                    let data = try Data(contentsOf: destUrl)
                    task.assetIndex = try .parse(data)
                } catch {
                    err("在解析 JSON 时发生错误: \(error.localizedDescription)")
                }
                continuation.resume()
            })
            downloader.start()
        }
    }
    
    // MARK: 下载散列资源文件
    private static func downloadHashResourcesFiles(_ task: InstallTask) async {
        task.updateStage(.clientResources)
        let objects = task.assetIndex!.objects
        
        var urls: [URL] = []
        var destinations: [URL] = []
        
        for object in objects {
            urls.append(object.appendTo(URL(string: "https://resources.download.minecraft.net")!))
            destinations.append(object.appendTo(task.minecraftDirectory.assetsUrl.appending(path: "objects")))
        }
        
        await withCheckedContinuation { continuation in
            let downloader = ProgressiveDownloader(
                task: task,
                urls: urls,
                destinations: destinations,
                concurrentLimit: 8,
                skipIfExists: true, completion: {
                continuation.resume()
            })
            downloader.start()
        }
    }
    
    // MARK: 下载依赖项
    private static func downloadLibraries(_ task: InstallTask) async {
        task.updateStage(.clientLibraries)
        
        var urls: [URL] = []
        var destinations: [URL] = []
        
        for library in task.manifest!.getNeededLibraries() {
            urls.append(URL(string: library.artifact!.url)!)
            destinations.append(task.minecraftDirectory.librariesUrl.appending(path: library.artifact!.path))
        }
        
        await withCheckedContinuation { continuation in
            let downloader = ProgressiveDownloader(
                task: task,
                urls: urls,
                destinations: destinations,
                skipIfExists: true,
                completion: {
                continuation.resume()
            })
            downloader.start()
        }
    }
    
    // MARK: 下载本地库
    private static func downloadNatives(_ task: InstallTask) async {
        task.updateStage(.natives)
        
        var urls: [URL] = []
        var destinations: [URL] = []
        
        for (_, artifact) in task.manifest!.getNeededNatives() {
            urls.append(URL(string: artifact.url)!)
            destinations.append(task.minecraftDirectory.librariesUrl.appending(path: artifact.path))
        }
        
        try? FileManager.default.createDirectory(at: task.versionUrl.appending(path: "natives"), withIntermediateDirectories: true)
        
        await withCheckedContinuation { continuation in
            let downloader = ProgressiveDownloader(
                task: task,
                urls: urls,
                destinations: destinations,
                skipIfExists: true,
                completion: {
                continuation.resume()
            })
            downloader.start()
        }
    }
    
    // MARK: 解压本地库
    private static func unzipNatives(_ task: InstallTask) {
        let nativesUrl: URL = task.versionUrl.appending(path: "natives")
        for (_, native) in task.manifest!.getNeededNatives() {
            let jarUrl: URL = task.minecraftDirectory.librariesUrl.appending(path: native.path)
            
            do {
                try FileManager.default.unzipItem(at: jarUrl, to: nativesUrl)
                processLibs(nativesUrl)
                debug("解压 \(native.path) 成功")
            } catch {
                err("无法解压本地库: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: 处理解压结果
    private static func processLibs(_ nativesUrl: URL) {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: nativesUrl, includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "dylib" || fileURL.pathExtension == "jnilib",
                  let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
                  !resourceValues.isDirectory! else { continue }
            do {
                let destinationURL = nativesUrl.appendingPathComponent(fileURL.lastPathComponent)
                if destinationURL == fileURL { continue }
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: fileURL, to: destinationURL)
            } catch {
                err("无法拷贝本地库: \(error.localizedDescription) (\(fileURL.path()) -> \(nativesUrl.path()))")
            }
        }
        
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(at: nativesUrl, includingPropertiesForKeys: nil)
            for fileURL in contents {
                if !fileURL.pathExtension.lowercased().hasSuffix("dylib") && !fileURL.pathExtension.lowercased().hasSuffix("jnilib") {
                    debug("已清除 \(fileURL.path())")
                    try fileManager.removeItem(at: fileURL)
                }
            }
        } catch {
            err("清理时发生错误: \(error.localizedDescription)")
        }
    }
    
    // MARK: 收尾
    private static func finalWork(_ task: InstallTask) {
        let _1_12_2 = MinecraftVersion(displayName: "1.12.2")
        // 拷贝 log4j2.xml
        let targetUrl: URL = task.versionUrl.appending(path: "log4j2.xml")
        if !FileManager.default.fileExists(atPath: targetUrl.path()) {
            do {
                try FileManager.default.copyItem(
                    at: SharedConstants.shared.applicationResourcesUrl.appending(path: task.minecraftVersion >= _1_12_2 ? "log4j2.xml" : "log4j2-1.12-.xml"),
                    to: targetUrl)
            } catch {
                err("无法拷贝 log4j2.xml: \(error.localizedDescription)")
            }
        }
        
        // 初始化实例
        let _ = MinecraftInstance.create(runningDirectory: task.versionUrl, config: MinecraftConfig(name: task.name, mainClass: task.manifest!.mainClass))
        
        // 修改 GLFW
        if let glfw = task.manifest!.getNeededLibraries().find({ $0.name.contains("lwjgl-glfw") }) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/java")
            process.environment = ProcessInfo.processInfo.environment
            process.currentDirectoryURL = URL(fileURLWithPath: "/tmp")
            process.arguments = ["-jar", SharedConstants.shared.applicationResourcesUrl.appending(path: "glfw-patcher.jar").path, task.minecraftDirectory.librariesUrl.appending(path: glfw.artifact!.path).path]
            do {
                try process.run()
                process.waitUntilExit()
                log("已修改 lwjgl-glfw")
            } catch {
                err("无法修改 lwjgl-glfw: \(error)")
            }
        }
    }
    
    // MARK: 获取进度
    public static func updateProgress(_ task: InstallTask) {
        DispatchQueue.main.async {
            task.totalFiles = 3 + task.assetIndex!.objects.count + task.manifest!.getNeededLibraries().count + task.manifest!.getNeededNatives().count
            log("总文件数: \(task.totalFiles)")
            task.remainingFiles = task.totalFiles - 2
        }
    }
    
    // MARK: 创建任务
    public static func createTask(_ minecraftVersion: MinecraftVersion, _ name: String, _ minecraftDirectory: MinecraftDirectory, _ callback: (() -> Void)? = nil) -> InstallTask {
        let task = InstallTask(minecraftVersion: minecraftVersion, minecraftDirectory: MinecraftDirectory(rootUrl: URL(fileURLWithUserPath: "~/PCL-Mac-minecraft")), name: name) { task in
            Task {
                await downloadClientManifest(task)
                await downloadAssetIndex(task)
                updateProgress(task)
                await downloadClientJar(task)
                await downloadHashResourcesFiles(task)
                await downloadLibraries(task)
                await downloadNatives(task)
                unzipNatives(task)
                finalWork(task)
                callback?()
            }
        }
        return task
    }
    
    // MARK: 创建补全资源任务
    public static func createCompleteTask(_ instance: MinecraftInstance, _ callback: (() -> Void)? = nil) -> InstallTask {
        let task = InstallTask(minecraftVersion: instance.version!, minecraftDirectory: instance.minecraftDirectory, name: instance.config.name) { task in
            Task {
                task.manifest = instance.manifest
                await downloadAssetIndex(task)
                await downloadClientJar(task, skipIfExists: true)
                await downloadHashResourcesFiles(task)
                await downloadLibraries(task)
                await downloadNatives(task)
                unzipNatives(task)
                finalWork(task)
                task.complete()
                callback?()
            }
        }
        return task
    }
}

// MARK: 安装任务定义
public class InstallTask: ObservableObject, Identifiable, Hashable, Equatable {
    public let id: UUID = UUID()
    public static func == (lhs: InstallTask, rhs: InstallTask) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    @Published public var stage: InstallStage = .before
    @Published public var remainingFiles: Int = -1
    @Published public var totalFiles: Int = -1
    
    public var manifest: ClientManifest?
    public var assetIndex: AssetIndex?
    public var name: String
    public var versionUrl: URL {
        get {
            return URL(fileURLWithUserPath: "~/PCL-Mac-minecraft/versions").appending(path: self.name)
        }
    }
    public let minecraftVersion: MinecraftVersion
    public let minecraftDirectory: MinecraftDirectory
    public let startTask: (InstallTask) -> Void
    
    public init(minecraftVersion: MinecraftVersion, minecraftDirectory: MinecraftDirectory, name: String, startTask: @escaping (InstallTask) -> Void) {
        self.minecraftVersion = minecraftVersion
        self.minecraftDirectory = minecraftDirectory
        self.name = name
        self.startTask = startTask
    }
    
    public func complete() {
        log("下载任务完成")
        self.updateStage(.end)
        DispatchQueue.main.async {
            DataManager.shared.inprogressInstallTask = nil
        }
    }
    
    public func start() {
        startTask(self)
    }
    
    public func updateStage(_ stage: InstallStage) {
        debug("切换阶段: \(stage.getDisplayName())")
        DispatchQueue.main.async {
            self.stage = stage
            DataManager.shared.currentStagePercentage = 0
        }
    }
    
    public func completeOneFile() {
        DispatchQueue.main.async {
            self.remainingFiles -= 1
        }
    }
    
    public func getProgress() -> Double {
        Double(totalFiles - remainingFiles) / Double(totalFiles)
    }
    
    public func getInstallStates() -> [InstallStage : InstallState] {
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
}

// MARK: 安装进度定义
public enum InstallStage: Int {
    case before = 0
    case clientJson = 1
    case clientIndex = 2
    case clientJar = 3
    case clientResources = 4
    case clientLibraries = 5
    case natives = 6
    case end = 7
    public func getDisplayName() -> String {
        switch self {
        case .before: "未启动"
        case .clientJson: "下载原版 json 文件"
        case .clientJar: "下载原版 jar 文件"
        case .clientIndex: "下载资源索引文件"
        case .clientResources: "下载散列资源文件"
        case .clientLibraries: "下载依赖项文件"
        case .natives: "下载本地库文件"
        case .end: "结束"
        }
    }
}

// MARK: 安装进度状态定义
public enum InstallState {
    case waiting, inprogress, finished, failed
    public func getImageName() -> String {
        return "Install\(String(describing: self).capitalized)"
    }
}

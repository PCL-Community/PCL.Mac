//
//  MinecraftInstallerNew.swift
//  PCL.Mac
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
    private static func downloadClientManifest(_ task: MinecraftInstallTask) async {
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
    private static func downloadClientJar(_ task: MinecraftInstallTask, skipIfExists: Bool = false) async {
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
    private static func downloadAssetIndex(_ task: MinecraftInstallTask) async {
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
    private static func downloadHashResourcesFiles(_ task: MinecraftInstallTask) async {
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
    private static func downloadLibraries(_ task: MinecraftInstallTask) async {
        task.updateStage(.clientLibraries)
        
        var urls: [URL] = []
        var destinations: [URL] = []
        
        for library in task.manifest!.getNeededLibraries() {
            let dest = task.minecraftDirectory.librariesUrl.appending(path: library.artifact!.path)
            if CacheStorage.default.copy(name: library.name, to: dest) {
                continue
            }
            urls.append(URL(string: library.artifact!.url)!)
            destinations.append(dest)
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
        
        for library in task.manifest!.getNeededLibraries() {
            if urls.contains(where: { $0.absoluteString == library.artifact!.url }) {
                CacheStorage.default.add(name: library.name, path: task.minecraftDirectory.librariesUrl.appending(path: library.artifact!.path))
            }
        }
    }
    
    // MARK: 下载本地库
    private static func downloadNatives(_ task: MinecraftInstallTask) async {
        task.updateStage(.natives)
        
        var urls: [URL] = []
        var destinations: [URL] = []
        
        for (library, artifact) in task.manifest!.getNeededNatives() {
            let dest = task.minecraftDirectory.librariesUrl.appending(path: artifact.path)
            if CacheStorage.default.copy(name: library.name, to: dest) {
                continue
            }
            urls.append(URL(string: artifact.url)!)
            destinations.append(dest)
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
        
        for (library, artifact) in task.manifest!.getNeededNatives() {
            if urls.contains(where: { $0.absoluteString == artifact.url }) {
                CacheStorage.default.add(name: library.name, path: task.minecraftDirectory.librariesUrl.appending(path: artifact.path))
            }
        }
    }
    
    // MARK: 解压本地库
    private static func unzipNatives(_ task: MinecraftInstallTask) {
        let nativesUrl: URL = task.versionUrl.appending(path: "natives")
        for (_, native) in task.manifest!.getNeededNatives() {
            let jarUrl: URL = task.minecraftDirectory.librariesUrl.appending(path: native.path)
            Util.unzip(archiveUrl: jarUrl, destination: nativesUrl, replace: true)
            processLibs(nativesUrl)
            debug("解压 \(native.path) 成功")
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
            
            // 验证架构
            if fileURL.pathExtension == "dylib" {
                let arch = ExecArchitectury.getArchOfFile(fileURL)
                guard arch == .SystemArch || arch == .fatFile else {
                    try? fileManager.removeItem(at: fileURL)
                    log("已清除架构不匹配的可执行文件: \(fileURL.lastPathComponent)")
                    continue
                }
            }
            
            // 拷贝到 natives 根目录
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
        
        // 清理非 dylib 文件
        do {
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
    private static func finalWork(_ task: MinecraftInstallTask) {
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
        let instance = MinecraftInstance.create(runningDirectory: task.versionUrl, config: MinecraftConfig(name: task.name, mainClass: task.manifest!.mainClass))
        if let _ = DataManager.shared.inprogressInstallTasks?.tasks["fabric"] {
            instance?.config.clientBrand = .fabric
        }
        instance?.saveConfig()
        
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
    public static func updateProgress(_ task: MinecraftInstallTask) {
        DispatchQueue.main.async {
            task.totalFiles = 3 + task.assetIndex!.objects.count + task.manifest!.getNeededLibraries().count + task.manifest!.getNeededNatives().count
            log("总文件数: \(task.totalFiles)")
            task.remainingFiles = task.totalFiles - 2
        }
    }
    
    // MARK: 创建任务
    public static func createTask(_ minecraftVersion: MinecraftVersion, _ name: String, _ minecraftDirectory: MinecraftDirectory, _ callback: (() -> Void)? = nil) -> InstallTask {
        let task = MinecraftInstallTask(minecraftVersion: minecraftVersion, minecraftDirectory: MinecraftDirectory(rootUrl: URL(fileURLWithUserPath: "~/PCL-Mac-minecraft")), name: name) { task in
            await downloadClientManifest(task)
            await downloadAssetIndex(task)
            updateProgress(task)
            if let fabricTask = DataManager.shared.inprogressInstallTasks?.tasks["fabric"] as? FabricInstallTask {
                fabricTask.start(task)
            }
            await downloadClientJar(task)
            await downloadHashResourcesFiles(task)
            await downloadLibraries(task)
            await downloadNatives(task)
            unzipNatives(task)
            finalWork(task)
            callback?()
        }
        return task
    }
    
    // MARK: 创建补全资源任务
    public static func createCompleteTask(_ instance: MinecraftInstance, _ callback: (() -> Void)? = nil) -> InstallTask {
        let task = MinecraftInstallTask(minecraftVersion: instance.version!, minecraftDirectory: instance.minecraftDirectory, name: instance.config.name) { task in
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
        return task
    }
}

//
//  ForgeInstaller.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/15.
//

import Foundation
import ZIPFoundation
import SwiftyJSON

public class ForgeInstaller {
    private let minecraftDirectory: MinecraftDirectory
    private let versionPath: URL
    private let manifest: ClientManifest
    private let temp: TemperatureDirectory
    private var installProfile: ForgeInstallProfile?
    private var values: [String: String] = [:]
    private var isOld: Bool = false
    private var updateProgress: ((Double) -> Void)?
    private var progress: Double = 0
    
    public init(_ minecraftDirectory: MinecraftDirectory, _ versionPath: URL, _ manifest: ClientManifest, updateProgress: ((Double) -> Void)? = nil) {
        self.minecraftDirectory = minecraftDirectory
        self.versionPath = versionPath
        self.manifest = manifest
        self.updateProgress = updateProgress
        self.temp = .init(name: "ForgeInstall")
    }
    
    // MARK: - 解析 data 中的值
    private func parseValue(_ value: String) -> String {
        let value = "\(value)"
        // 若被 [ ] 包裹，解析中间部分的 Maven 坐标并拼接到 libraries 后
        if let match = value.wholeMatch(of: /\[(.*?)\]/) {
            return minecraftDirectory.librariesURL.appending(path: Util.toPath(mavenCoordinate: String(match.1))).path
        } else if let match = value.wholeMatch(of: /\'(.*?)\'/) {
            // 若被 ' ' 包裹，去除 ' '
            return String(match.1)
        }
        
        return value
    }
    
    // MARK: - 解析 data
    @MainActor private func parseValues() throws {
        guard let installProfile else {
            return
        }
        
        // 创建默认键值对
        values["SIDE"] = "client"
        values["INSTALLER"] = temp.root.appending(path: "installer.jar").path
        values["MINECRAFT_JAR"] = versionPath.appending(path: "\(versionPath.lastPathComponent).jar").path
        values["MINECRAFT_VERSION"] = values["MINECRAFT_JAR"]!
        values["ROOT"] = minecraftDirectory.rootURL.path
        values["LIBRARY_DIR"] = minecraftDirectory.librariesURL.path
        
        let step: Double = 0.1 / Double(installProfile.data.count)
        
        for (key, value) in installProfile.data {
            log("正在解析 \(key) 的值")
            if value.starts(with: "/") {
                let archive = try Archive(url: temp.getURL(path: "installer.jar"), accessMode: .read)
                let data = try ArchiveUtil.getEntryOrThrow(archive: archive, name: String(value.dropFirst(1)))
                if let url = temp.createFile(path: value, data: data) {
                    values[key] = url.path
                }
            } else {
                let parsed = parseValue(value)
                values[key] = parsed
            }
            
            increaseProgress(step)
        }
    }
    
    // MARK: - 替换字符串中的占位符
    private func replaceWithValue(_ string: String) -> String {
        let string = parseValue(string)
        // 如果字符串中不存在 { }，直接返回来节省资源
        if !string.contains("{") || !string.contains("}") { return string }
        
        for (key, value) in values {
            if string.contains("{\(key)}") {
                return string.replacingOccurrences(of: "{\(key)}", with: value)
            }
        }
        
        return string
    }
    
    // MARK: - 执行处理器任务
    private func executeProcessor(_ processor: ForgeInstallProfile.Processor) throws {
        let processorPath = minecraftDirectory.librariesURL.appending(path: processor.jarPath)
        guard let mainClass = Util.getMainClass(processorPath) else {
            warn("\(processorPath.lastPathComponent) 没有主类")
            return
        }
        
        let process = Process()
        process.currentDirectoryURL = temp.root
        process.executableURL = URL(fileURLWithPath: "/usr/bin/java")
        process.arguments = [
            // processor 初始化逻辑中往 classpath 里添加了它本身的 jar，这里直接 map
            "-cp", processor.classpath.map { minecraftDirectory.librariesURL.appending(path: $0).path }.joined(separator: ":"),
            mainClass
        ]
        process.arguments!.append(contentsOf: processor.args.map(replaceWithValue(_:)))
        try process.run()
        process.waitUntilExit()
    }
    
    // MARK: - 修改 DOWNLOAD_MOJMAPS 任务
    private func patchMojangMappingsDownloadTask(_ processor: ForgeInstallProfile.Processor) async throws -> Bool {
        // 若参数中不存在 --output，或 --output 后没有参数，返回
        guard let index = processor.args.firstIndex(of: "--output"),
              index + 1 < processor.args.count else {
            return false
        }
        
        // 若实例的 client_mappings 下载项不存在，跳过
        guard let clientMappingsDownload = manifest.clientMappingsDownload else {
            return false
        }
        
        // 下载 mappings
        let url = clientMappingsDownload.url
        let destination = URL(fileURLWithPath: replaceWithValue(processor.args[index + 1]))
        
        try? FileManager.default.createDirectory(at: destination.parent(), withIntermediateDirectories: true)
        try await SingleFileDownloader.download(url: url.url, destination: destination, replaceMethod: .replace)
        debug("已修改 DOWNLOAD_MOJMAPS 任务")
        
        return true
    }
    
    // MARK: - 执行所有处理器任务
    private func executeProcessors() async throws {
        guard let installProfile else {
            throw MyLocalizedError(reason: "installProfile 为空")
        }
        
        let processors = installProfile.processors.filter { $0.isAvailableOnClient }
        let step = 0.4 / Double(processors.count)
        
        for processor in processors {
            if processor.args.contains("DOWNLOAD_MOJMAPS") {
                if try await patchMojangMappingsDownloadTask(processor) {
                    continue
                }
            }
            if let index = processor.args.firstIndex(of: "--task") {
                log("正在执行安装器 \(processor.args[index + 1])")
            }
            try executeProcessor(processor)
            await increaseProgress(step)
        }
    }
    
    // MARK: - 下载安装器
    private func downloadInstaller(minecraftVersion: MinecraftVersion, version: String) async throws {
        let installerPath = temp.getURL(path: "installer.jar")
        // 如果 CacheStorage 中不存在安装器，下载
        let name = "\(getGroupId()):installer:\(minecraftVersion.displayName)-\(version)"
        if !CacheStorage.default.copy(name: name, to: installerPath) {
            let url = getInstallerDownloadURL(minecraftVersion, version)
            let dest = temp.getURL(path: "installer.jar")
            log("正在下载安装器 \(url.lastPathComponent)")
            try await SingleFileDownloader.download(url: url, destination: dest) { progress in
                Task { @MainActor in self.setProgress(progress * 0.2) }
            }
            log("安装器下载完成")
            CacheStorage.default.add(name: name, path: dest)
        }
        await setProgress(0.2)
    }
    
    // MARK: - 加载 install_profile.json
    private func loadInstallProfile() throws {
        let installerPath = temp.getURL(path: "installer.jar")
        let archive = try Archive(url: installerPath, accessMode: .read)
        let json = try JSON(data: try ArchiveUtil.getEntryOrThrow(archive: archive, name: "install_profile.json"))
        
        if json["install"].exists() {
            isOld = true
            log("该安装器为旧版格式")
            temp.createFile(path: "manifest.json", data: try json["versionInfo"].rawData())
            
            let forgePath = minecraftDirectory.librariesURL.appending(path: Util.toPath(mavenCoordinate: json["install"]["path"].stringValue))
            
            try? FileManager.default.createDirectory(at: forgePath.parent(), withIntermediateDirectories: true)
            try ArchiveUtil.getEntryOrThrow(archive: archive, name: json["install"]["filePath"].stringValue).write(to: forgePath)
        } else {
            installProfile = ForgeInstallProfile(json: json)
            temp.createFile(path: "manifest.json", data: try ArchiveUtil.getEntryOrThrow(archive: archive, name: "version.json"))
        }
    }
    
    // MARK: - 拷贝客户端清单
    private func copyManifest(version: MinecraftVersion) throws {
        try loadInstallProfile()
        let manifestURL = versionPath.appending(path: "\(versionPath.lastPathComponent).json")
        
        // 若 inheritsFrom 对应的版本 JSON 不存在，复制
        let baseManifestURL = minecraftDirectory.versionsURL.appending(path: version.displayName).appending(path: "\(version.displayName).json")
        if !FileManager.default.fileExists(atPath: baseManifestURL.path) {
            try? FileManager.default.createDirectory(at: baseManifestURL.parent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: manifestURL, to: baseManifestURL)
        }
        
        try FileManager.default.removeItem(at: manifestURL)
        try FileManager.default.copyItem(at: temp.getURL(path: "manifest.json"), to: manifestURL)
        log("客户端清单拷贝完成")
    }
    
    // MARK: - 下载安装器与加载器依赖
    private func downloadDependencies() async throws {
        log("正在下载依赖项")
        var libraries: [ClientManifest.Library] = []
        if isOld {
            if let manifest = try ClientManifest.parse(url: temp.getURL(path: "manifest.json")) {
                libraries.append(contentsOf: manifest.libraries)
            }
        } else {
            guard let installProfile else {
                throw MyLocalizedError(reason: "installProfile 为空")
            }
            libraries.append(contentsOf: installProfile.libraries)
        }
        
        let artifacts = libraries.compactMap { $0.artifact }
        
        let downloader = MultiFileDownloader(
            urls: libraries.compactMap(DownloadSourceManager.shared.getLibraryURL(_:)),
            destinations: artifacts.map { minecraftDirectory.librariesURL.appending(path: $0.path) },
            replaceMethod: .skip
        ) { progress, _ in
            Task { @MainActor in
                self.setProgress(0.3 + progress * 0.3)
            }
        }
        
        try await downloader.start()
    }
    
    // MARK: - 安装函数
    public func install(minecraftVersion: MinecraftVersion, forgeVersion: String) async throws {
        try await downloadInstaller(minecraftVersion: minecraftVersion, version: forgeVersion)
        try copyManifest(version: minecraftVersion)
        try await parseValues()
        try await downloadDependencies()
        
        if !isOld {
            try await executeProcessors()
        }
        
        await setProgress(1.0)
        temp.free()
    }
    
    
    func getInstallerDownloadURL(_ minecraftVersion: MinecraftVersion, _ version: String) -> URL {
        return URL(string: "https://bmclapi2.bangbang93.com/forge/download"
            + "?mcversion=\(minecraftVersion.displayName)"
            + "&version=\(version)"
            + "&category=installer"
            + "&format=jar"
        )!
    }
    
    func getGroupId() -> String { "net.minecraftforge" }
    
    @MainActor
    private func increaseProgress(_ value: Double) {
        setProgress(progress + value)
    }
    
    @MainActor
    private func setProgress(_ value: Double) {
        progress = value
        updateProgress?(progress)
    }
}

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
    
    public init(_ minecraftDirectory: MinecraftDirectory, _ versionPath: URL, _ manifest: ClientManifest) {
        self.minecraftDirectory = minecraftDirectory
        self.versionPath = versionPath
        self.manifest = manifest
        self.temp = .init(name: "ForgeInstall")
    }
    
    private func parseValues() throws {
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
        
        for (key, value) in installProfile.data {
            // 若被 [ ] 包裹，解析中间部分的 Maven 坐标并拼接到 libraries 后
            if let match = value.wholeMatch(of: /\[(.*?)\]/) {
                values[key] = minecraftDirectory.librariesURL.appending(path: Util.toPath(mavenCoordinate: String(match.1))).path
            } else if let match = value.wholeMatch(of: /\'(.*?)\'/) {
                // 若被 ' ' 包裹，去除 ' '
                values[key] = String(match.1)
            } else if value.starts(with: "/") {
                // 若以 / 开头 (/data/client.lzma)，从 jar 根目录复制到临时目录
                let archive = try Archive(url: temp.getURL(path: "installer.jar"), accessMode: .read)
                let data = try ZipUtil.getEntryOrThrow(archive: archive, name: String(value.dropFirst(1)))
                if let path = temp.createFile(path: value, data: data) {
                    values[key] = path.path
                }
            } else {
                warn("未知的格式: \(value)")
            }
        }
    }
    
    private func replaceWithValue(_ string: String) -> String {
        // 如果字符串中不存在 { }，直接返回来节省资源
        if !string.contains("{") || !string.contains("}") { return string }
        
        for (key, value) in values {
            if string.contains("{\(key)}") {
                return string.replacingOccurrences(of: "{\(key)}", with: value)
            }
        }
        
        return string
    }
    
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
        try await Requests.get(url).getDataOrThrow().write(to: destination)
        debug("已修改 DOWNLOAD_MOJMAPS 任务")
        
        return true
    }
    
    private func executeProcessors() async throws {
        guard let installProfile else {
            throw MyLocalizedError(reason: "installProfile 为空")
        }
        let processors = installProfile.processors.filter { $0.isAvaliableOnClient }
        
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
        }
    }
    
    private func downloadInstaller(minecraftVersion: MinecraftVersion, version: String) async throws {
        let installerPath = temp.getURL(path: "installer.jar")
        // 如果 CacheStorage 中不存在安装器，下载
        if !CacheStorage.default.copy(name: "net.minecraftforge:installer:\(minecraftVersion.displayName)-\(version)", to: installerPath) {
            let data = try await Requests.get(
                "https://bmclapi2.bangbang93.com/forge/download"
                + "?mcversion=\(minecraftVersion.displayName)"
                + "&version=\(version)"
                + "&category=installer"
                + "&format=jar"
            ).getDataOrThrow()
            
            if let url = temp.createFile(path: "installer.jar", data: data) {
                CacheStorage.default.add(name: "net.minecraftforge:installer:\(minecraftVersion.displayName)-\(version)", path: url)
            }
        }
    }
    
    private func loadInstallProfile() throws {
        let installerPath = temp.getURL(path: "installer.jar")
        let archive = try Archive(url: installerPath, accessMode: .read)
        let json = try JSON(data: try ZipUtil.getEntryOrThrow(archive: archive, name: "install_profile.json"))
        
        if json["install"].exists() {
            isOld = true
            log("该安装器为旧版格式")
            temp.createFile(path: "manifest.json", data: try json["versionInfo"].rawData())
            
            let forgePath = minecraftDirectory.librariesURL.appending(path: Util.toPath(mavenCoordinate: json["install"]["path"].stringValue))
            
            try? FileManager.default.createDirectory(at: forgePath.parent(), withIntermediateDirectories: true)
            try ZipUtil.getEntryOrThrow(archive: archive, name: json["install"]["filePath"].stringValue).write(to: forgePath)
        } else {
            installProfile = ForgeInstallProfile(json: json)
            temp.createFile(path: "manifest.json", data: try ZipUtil.getEntryOrThrow(archive: archive, name: "version.json"))
        }
    }
    
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
    }
    
    private func downloadDependencies() async throws {
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
        
        let urls = artifacts.map { URL(string: $0.url)! }
        let destinations = artifacts.map { minecraftDirectory.librariesURL.appending(path: $0.path) }
        
        await withCheckedContinuation { continuation in
            let downloader = ProgressiveDownloader(
                urls: urls,
                destinations: destinations,
                skipIfExists: true,
                completion: continuation.resume
            )
            downloader.start()
        }
    }
    
    public func install(minecraftVersion: MinecraftVersion, forgeVersion: String) async throws {
        try await downloadInstaller(minecraftVersion: minecraftVersion, version: forgeVersion)
        try parseValues()
        try copyManifest(version: minecraftVersion)
        try await downloadDependencies()
        
        if !isOld {
            try await executeProcessors()
        }
        
        temp.free()
    }
}

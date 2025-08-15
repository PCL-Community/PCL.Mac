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
    
    public init(_ minecraftDirectory: MinecraftDirectory, _ versionPath: URL, _ manifest: ClientManifest) {
        self.minecraftDirectory = minecraftDirectory
        self.versionPath = versionPath
        self.manifest = manifest
        self.temp = .init(name: "ForgeInstall")
    }
    
    private func parseValues() throws {
        guard let installProfile else {
            throw MyLocalizedError(reason: "installProfile 为空")
        }
        
        // 创建默认键值对
        values["SIDE"] = "client"
        values["INSTALLER"] = temp.root.appending(path: "installer.jar").path
        values["MINECRAFT_JAR"] = versionPath.appending(path: "\(versionPath.lastPathComponent).jar").path
        values["MINECRAFT_VERSION"] = values["MINECRAFT_JAR"]!
        values["ROOT"] = minecraftDirectory.rootURL.path
        values["LIBRARY_DIR"] = minecraftDirectory.librariesURL.path
        
        for (key, value) in installProfile.data {
            // 若被 [] 包裹，解析中间部分的 Maven 坐标并拼接到 libraries 后
            if let match = value.wholeMatch(of: /\[(.*?)\]/) {
                values[key] = minecraftDirectory.librariesURL.appending(path: Util.toPath(mavenCoordinate: String(match.1))).path
            } else if let match = value.wholeMatch(of: /\'(.*?)\'/) {
                values[key] = String(match.1)
            } else if value.starts(with: "/") {
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
            "-cp", processor.classpath.map { minecraftDirectory.librariesURL.appending(path: $0).path }.joined(separator: ":"),
            mainClass
        ]
        process.arguments!.append(contentsOf: processor.args.map(replaceWithValue(_:)))
        try process.run()
        process.waitUntilExit()
    }
    
    private func patchMojangMappingsDownloadTask(_ processor: ForgeInstallProfile.Processor) async throws -> Bool {
        guard let index = processor.args.firstIndex(of: "--output"),
              index + 1 < processor.args.count else {
            return false
        }
        
        guard let clientMappingsDownload = manifest.clientMappingsDownload else {
            return false
        }
        
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
            log("正在执行安装器 \(processor.args[1])")
            try executeProcessor(processor)
        }
    }
    
    private func downloadInstaller(minecraftVersion: MinecraftVersion, version: String) async throws {
        let installerPath = temp.getURL(path: "installer.jar")
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
        
        let archive = try Archive(url: installerPath, accessMode: .read)
        let data = try ZipUtil.getEntryOrThrow(archive: archive, name: "install_profile.json")
        installProfile = ForgeInstallProfile(json: try JSON(data: data))
    }
    
    private func copyManifest(version: MinecraftVersion) throws {
        let manifestURL = versionPath.appending(path: "\(versionPath.lastPathComponent).json")
        
        // 若 inheritsFrom 对应的版本 JSON 不存在，复制
        let baseManifestURL = minecraftDirectory.versionsURL.appending(path: version.displayName).appending(path: "\(version.displayName).json")
        if !FileManager.default.fileExists(atPath: baseManifestURL.path) {
            try? FileManager.default.createDirectory(at: baseManifestURL.parent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: manifestURL, to: baseManifestURL)
        }
        try FileManager.default.removeItem(at: manifestURL)
        
        let url = temp.getURL(path: "installer.jar")
        let archive = try Archive(url: url, accessMode: .read)
        let data = try ZipUtil.getEntryOrThrow(archive: archive, name: "version.json")
        try data.write(to: manifestURL)
    }
    
    private func downloadDependencies() async throws {
        guard let installProfile else {
            throw MyLocalizedError(reason: "installProfile 为空")
        }
        
        let artifacts = installProfile.libraries.compactMap { $0.artifact }
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
        try await executeProcessors()
        
        temp.free()
    }
}

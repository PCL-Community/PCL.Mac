//
//  DownloadSourceManager.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/20.
//

import Foundation

public class DownloadSourceManager: DownloadSource {
    public static let shared: DownloadSourceManager = .init()
    
    private let official: OfficialDownloadSource = .init()
    private let bmclapi: BMCLAPIDownloadSource = .init()
    
    private var lastTestDate: Date = .init(timeIntervalSince1970: 0)
    private var fileDownloadSource: DownloadSource
    private var versionManifestSource: DownloadSource
    
    private func getDownloadSource() -> DownloadSource {
        if AppSettings.shared.fileDownloadSource == .both {
            if Date().timeIntervalSince(lastTestDate) > 1 * 60 {
                lastTestDate = Date()
                Task {
                    log("正在进行官方源测速")
                    await testSpeed("https://libraries.minecraft.net/net/java/dev/jna/jna/5.15.0/jna-5.15.0.jar", &fileDownloadSource)
                }
            }
            return fileDownloadSource
        } else {
            return AppSettings.shared.fileDownloadSource == .mirror ? bmclapi : fileDownloadSource
        }
    }
    
    public func getVersionManifestURL() -> URL {
        versionManifestSource.getVersionManifestURL()
    }
    
    public func getClientManifestURL(_ version: MinecraftVersion) -> URL? {
        getDownloadSource().getClientManifestURL(version)
    }
    
    public func getAssetIndexURL(_ version: MinecraftVersion, _ manifest: ClientManifest) -> URL? {
        getDownloadSource().getAssetIndexURL(version, manifest)
    }
    
    public func getClientJARURL(_ version: MinecraftVersion, _ manifest: ClientManifest) -> URL? {
        getDownloadSource().getClientJARURL(version, manifest)
    }
    
    public func getLibraryURL(_ library: ClientManifest.Library) -> URL? {
        getDownloadSource().getLibraryURL(library)
    }
    
    public func testSpeed(_ url: URLConvertible, _ source: inout DownloadSource) async {
        source = official
        let before = Date()
        guard let data = try? await Requests.get(url).getDataOrThrow() else {
            return
        }
        
        let timeUsed: Double = Date().timeIntervalSince(before)
        let speed = Double(data.count) / timeUsed / 1024 / 1024
        debug(String(format: "\(url.url.lastPathComponent) 下载耗时 %.2fs (%.2f MB/s)", timeUsed, speed))
        if speed < 1 { // 1 MB
            source = bmclapi
            debug("已切换至镜像源")
        }
    }
    
    private init() {
        self.fileDownloadSource = official
        self.versionManifestSource = AppSettings.shared.versionManifestSource == .mirror ? bmclapi : official
    }
}

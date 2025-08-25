//
//  DownloadSource.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/20.
//

import Foundation

public protocol DownloadSource {
    // Minecraft
    func getVersionManifestURL() -> URL
    func getClientManifestURL(_ version: MinecraftVersion) -> URL?
    func getAssetIndexURL(_ version: MinecraftVersion, _ manifest: ClientManifest) -> URL?
    func getClientJARURL(_ version: MinecraftVersion, _ manifest: ClientManifest) -> URL?
    func getLibraryURL(_ library: ClientManifest.Library) -> URL?
}

public class OfficialDownloadSource: DownloadSource {
    public static let shared: OfficialDownloadSource = .init()
    
    public func getVersionManifestURL() -> URL {
        "https://piston-meta.mojang.com/mc/game/version_manifest.json".url
    }
    
    public func getClientManifestURL(_ version: MinecraftVersion) -> URL? {
        return try? URL(string: DataManager.shared.versionManifest!.versions.find { $0.id == version.displayName }.unwrap().url)
    }
    
    public func getAssetIndexURL(_ version: MinecraftVersion, _ manifest: ClientManifest) -> URL? {
        return URL(string: manifest.assetIndex?.url ?? "")
    }
    
    public func getClientJARURL(_ version: MinecraftVersion, _ manifest: ClientManifest) -> URL? {
        return try? URL(string: manifest.clientDownload.unwrap().url)
    }
    
    public func getLibraryURL(_ library: ClientManifest.Library) -> URL? {
        return URL(string: library.artifact?.url ?? "")
    }
}

public class BMCLAPIDownloadSource: DownloadSource {
    public static let shared: BMCLAPIDownloadSource = .init()
    
    public func getVersionManifestURL() -> URL {
        "https://piston-meta.mojang.com/mc/game/version_manifest.json".url
    }
    
    public func getClientManifestURL(_ version: MinecraftVersion) -> URL? {
        return URL(string: "https://bmclapi2.bangbang93.com/version/\(version.displayName)/json")!
    }
    
    public func getAssetIndexURL(_ version: MinecraftVersion, _ manifest: ClientManifest) -> URL? {
        guard let urlString = manifest.assetIndex?.url,
              let url = URL(string: urlString) else {
            return nil
        }
        return URL(string: "https://bmclapi2.bangbang93.com")!.appending(path: url.path)
    }
    
    public func getClientJARURL(_ version: MinecraftVersion, _ manifest: ClientManifest) -> URL? {
        return URL(string: "https://bmclapi2.bangbang93.com/version/\(version.displayName)/client")!
    }
    
    public func getLibraryURL(_ library: ClientManifest.Library) -> URL? {
        return URL(string: "https://bmclapi2.bangbang93.com/maven")!.appending(path: Util.toPath(mavenCoordinate: library.name))
    }
}

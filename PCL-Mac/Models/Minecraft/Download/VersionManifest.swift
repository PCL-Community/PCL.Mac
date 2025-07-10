//
//  VersionManifest.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/5/20.
//

import Foundation
import SwiftyJSON
import Alamofire

public class VersionManifest: Codable {
    public static var aprilFoolVersions: [String] = []
    
    public let latest: LatestVersions
    public let versions: [GameVersion]
    
    public init(_ json: JSON) {
        self.latest = LatestVersions(json["latest"])
        self.versions = json["versions"].arrayValue.map(GameVersion.init)
    }
    
    public struct LatestVersions: Codable {
        public let release: String
        public let snapshot: String
        
        public init(_ json: JSON) {
            self.release = json["release"].stringValue
            self.snapshot = json["snapshot"].stringValue
        }
    }
    
    public struct GameVersion: Codable, Hashable {
        public enum VersionType: String, Codable {
            case release = "release"
            case snapshot = "snapshot"
            case oldBeta = "old_beta"
            case alpha = "old_alpha"
            case aprilFool = "april_fool"
        }
        
        public let id: String
        public let type: String
        public let url: String
        public let time: Date
        public let releaseTime: Date
        
        public init(_ json: JSON) {
            let formatter = ISO8601DateFormatter()
            self.id = json["id"].stringValue.replacing(" Pre-Release ", with: "-pre")
            self.type = aprilFoolVersions.contains(id) ? "april_fool" : json["type"].stringValue
            self.url = json["url"].stringValue
            self.time = formatter.date(from: json["time"].stringValue)!
            self.releaseTime = formatter.date(from: json["releaseTime"].stringValue)!
        }
        
        public func parse() -> MinecraftVersion {
            MinecraftVersion(displayName: id, type: .init(rawValue: type))
        }
    }
    
    public static func fetchLatestData() async -> VersionManifest? {
        debug("正在获取最新版本数据")
        Task {
            if let data = try? await AF.request(
                "https://gitee.com/yizhimcqiu/pcl-mac-announcements/raw/main/april_fool_versions.json"
            )
                .serializingResponse(using: .data).value {
                if let json = try? JSON(data: data) {
                    aprilFoolVersions = json.arrayValue.map { $0.stringValue }
                }
            }
        }
        
        if let data = try? await AF.request(
            "https://launchermeta.mojang.com/mc/game/version_manifest.json"
        )
            .serializingResponse(using: .data).value {
            if let json = try? JSON(data: data) {
                return .init(json)
            }
        }
        
        return nil
    }
    
    public func getLatestRelease() -> GameVersion {
        return self.versions.find { $0.id == self.latest.release }!
    }
    
    public func getLatestSnapshot() -> GameVersion {
        return self.versions.find { $0.id == self.latest.snapshot }!
    }
    
    public static func getReleaseDate(_ version: MinecraftVersion) -> Date? {
        if let manifest = DataManager.shared.versionManifest {
            return manifest.versions.find { $0.id == version.displayName }?.releaseTime // 需要缓存
        } else {
            warn("正在获取 \(version.displayName) 的发布日期，但版本清单未初始化完成") // 哦天呐，不会吧哥们
        }
        return nil
    }
}

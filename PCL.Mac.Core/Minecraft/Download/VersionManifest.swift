//
//  VersionManifest.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/20.
//

import Foundation
import SwiftyJSON

public class VersionManifest: Codable {
    public let latest: LatestVersions
    public fileprivate(set) var versions: [GameVersion]
    
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
    
    public class GameVersion: Codable, Hashable {
        public let id: String
        public fileprivate(set) var type: VersionType
        public fileprivate(set) var url: String
        public let time: Date
        public let releaseTime: Date
        
        public init(_ json: JSON) {
            let formatter = ISO8601DateFormatter()
            self.id = json["id"].stringValue.replacing(" Pre-Release ", with: "-pre")
            self.type = .init(rawValue: json["type"].stringValue) ?? .release
            self.url = json["url"].stringValue
            self.time = formatter.date(from: json["time"].stringValue)!
            self.releaseTime = formatter.date(from: json["releaseTime"].stringValue)!
            
            if VersionManifest.isAprilFoolVersion(self) {
                self.type = .aprilFool
            }
        }
        
        public func parse() -> MinecraftVersion {
            MinecraftVersion(displayName: id, type: type)
        }
        
        public static func == (lhs: GameVersion, rhs: GameVersion) -> Bool { lhs.id == rhs.id }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    public static func getVersionManifest() async -> VersionManifest? {
        debug("正在获取版本清单")
        do {
            let versions = VersionManifest(try await Requests.get("https://piston-meta.mojang.com/mc/game/version_manifest.json").getJSONOrThrow())
            if let unlistedVersions = await Requests.get("https://alist.8mi.tech/d/mirror/unlisted-versions-of-minecraft/Auto/version_manifest.json").json.map(VersionManifest.init(_:)) {
                for version in unlistedVersions.versions {
                    version.url = Util.replaceRoot(
                        url: version.url,
                        root: "https://zkitefly.github.io/unlisted-versions-of-minecraft",
                        target: "https://alist.8mi.tech/d/mirror/unlisted-versions-of-minecraft/Auto"
                    ).url.absoluteString
                }
                versions.versions.append(contentsOf: unlistedVersions.versions)
                versions.versions.sort { $0.releaseTime > $1.releaseTime }
            }
            return versions
        } catch {
            err("无法获取版本清单: \(error.localizedDescription)")
            return nil
        }
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
    
    public static func isAprilFoolVersion(_ version: GameVersion) -> Bool {
        let calendar = Calendar.current
        let releaseDateWithOffset = version.releaseTime.addingTimeInterval(2 * 3600)
        let components = calendar.dateComponents([.month, .day], from: releaseDateWithOffset)
        return components.month == 4 && components.day == 1
    }
}

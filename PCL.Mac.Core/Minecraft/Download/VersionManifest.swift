//
//  VersionManifest.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/20.
//

import Foundation
import SwiftyJSON

public class VersionManifest: Codable {
    private static let aprilFoolVersions: [String] = ["15w14a", "1.rv-pre1", "3d shareware v1.34", "20w14infinite", "22w13oneblockatatime", "23w13a_or_b", "24w14potato", "25w14craftmine"]
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
        public fileprivate(set) var id: String
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
            let versions = VersionManifest(try await Requests.get(DownloadSourceManager.shared.getVersionManifestURL()).getJSONOrThrow())
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
        version.id = version.id.replacingOccurrences(of: "point", with: ".")
        if aprilFoolVersions.contains(version.id.lowercased()) { return true }
        return version.type == .snapshot // 是快照
            && version.id.wholeMatch(of: /[0-9]{2}w[0-9]{2}.{1}/) == nil // 且不是标准快照格式 (如 23w33a)
            && version.id.rangeOfCharacter(from: .letters) != nil // 至少有一个字母 (筛掉 1.x 与 1.x.x)
            && !version.id.contains("-pre") && !version.id.contains("-rc") // 不是 Pre Release 或 Release Candidate
    }
    
    public static func getAprilFoolDescription(_ name: String) -> String {
        let name = name.lowercased()
        var tag = ""
        if name.hasPrefix("2.0") || name.hasPrefix("2point0") {
            if name.hasSuffix("red") {
                tag = "（红色版本）"
            } else if name.hasSuffix("blue") {
                tag = "（蓝色版本）"
            } else if name.hasSuffix("purple") {
                tag = "（紫色版本）"
            }
            return "2013 | 这个秘密计划了两年的更新将游戏推向了一个新高度！" + tag
        } else if name == "15w14a" {
            return "2015 | 作为一款全年龄向的游戏，我们需要和平，需要爱与拥抱。"
        } else if name == "1.rv-pre1" {
            return "2016 | 是时候将现代科技带入 Minecraft 了！"
        } else if name == "3d shareware v1.34" {
            return "2019 | 我们从地下室的废墟里找到了这个开发于 1994 年的杰作！"
        } else if name.hasPrefix("20w14inf") || name == "20w14∞" {
            return "2020 | 我们加入了 20 亿个新的维度，让无限的想象变成了现实！"
        } else if name == "22w13oneblockatatime" {
            return "2022 | 一次一个方块更新！迎接全新的挖掘、合成与骑乘玩法吧！"
        } else if name == "23w13a_or_b" {
            return "2023 | 研究表明：玩家喜欢作出选择——越多越好！"
        } else if name == "24w14potato" {
            return "2024 | 毒马铃薯一直都被大家忽视和低估，于是我们超级加强了它！"
        } else if name == "25w14craftmine" {
            return "2025 | 你可以合成任何东西——包括合成你的世界！"
        } else {
            return ""
        }
    }
}

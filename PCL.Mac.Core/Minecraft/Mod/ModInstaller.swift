//
//  ModDownloader.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/19.
//

import Foundation
import Alamofire
import SwiftyJSON
import SwiftUI

public struct ModPlatformKey: Hashable, Comparable {
    public static func < (lhs: ModPlatformKey, rhs: ModPlatformKey) -> Bool {
        lhs.minecraftVersion < rhs.minecraftVersion
    }
    
    let loader: ClientBrand
    let minecraftVersion: MinecraftVersion
}

public struct ModDependency: Identifiable {
    public enum DependencyType: String {
        case required, optional, unsupported, unknown
    }
    
    public let id: UUID = .init()
    let type: DependencyType
    var summary: ModSummary? = nil
    
    init(type: DependencyType, summary: ModSummary? = nil) {
        self.type = type
        self.summary = summary
    }
}

public struct ModVersion: Hashable, Identifiable {
    public let id: UUID = .init()
    
    let name: String
    let version: String
    let releaseDate: Date
    let type: String
    let downloadUrl: URL
    let filename: String
    
    func getDescription() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .full
        let result = formatter.localizedString(for: releaseDate, relativeTo: Date()).replacingOccurrences(of: "(\\d+)", with: " $1 ", options: .regularExpression)
        let typeText = switch type {
        case "release":
            "正式版"
        case "beta", "alpha":
            "测试版"
        default:
            "未知"
        }
        return filename[filename.startIndex...filename.index(filename.endIndex, offsetBy: -5)]
        + "，更新于\(result)"
        + "，\(typeText)"
    }
}

public typealias ModVersionMap = [ModPlatformKey: [ModVersion]]

@MainActor
public class ModSummary: ObservableObject, Identifiable, Hashable, Equatable {
    public let id: UUID = .init()
    
    public let slug: String
    public let title: String
    public let description: String
    public var tags: [String] = []
    public var loaders: [ClientBrand] = []
    public var supportDescription: String = ""
    public var downloads: String = ""
    public var lastUpdate: String = ""
    public let infoUrl: URL
    private let loadVersions: () async -> ModVersionMap
    @Published public var versions: ModVersionMap?
    @Published public var icon: Image?
    @Published public var dependencies: [ModDependency] = []
    
    nonisolated public static func == (lhs: ModSummary, rhs: ModSummary) -> Bool {
        lhs.id == rhs.id
    }
    
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(description)
    }
    
    static func getFrom(_ slug: String) async -> ModSummary? {
        if let data = try? await AF.request(
            "https://api.modrinth.com/v2/project/\(slug)"
        ).serializingResponse(using: .data).value {
            return ModrinthModSearcher.default.getFromJson(JSON(data))
        }
        return nil
    }
    
    init(slug: String, title: String, description: String, categories: [String], supportedVersions: [String]?, downloads: Int, lastUpdate: Date, infoUrl: URL, iconUrl: URL?, loadVersions: @escaping () async -> ModVersionMap) {
        self.slug = slug
        self.title = title
        self.description = description
        self.infoUrl = infoUrl
        self.loadVersions = loadVersions
        
        for category in categories {
            if let clientBrand = ClientBrand(rawValue: category) {
                self.loaders.append(clientBrand)
                continue
            }
            
            let tag: String? = switch category {
            case "technology": "科技"
            case "magic": "魔法"
            case "adventure": "冒险"
            case "utility": "实用"
            case "optimization": "性能优化"
            case "vanilla-like": "原版风"
            case "realistic": "写实风"
            case "worldgen": "世界元素"
            case "food": "食物/烹饪"
            case "game-mechanics": "游戏机制"
            case "transportation": "运输"
            case "storage": "仓储"
            case "decoration": "装饰"
            case "mobs": "生物"
            case "equipment": "装备"
            case "social": "服务器"
            case "library": "支持库"
            case "multiplayer": "多人"
            case "challenging": "硬核"
            case "combat": "战斗"
            case "quests": "任务"
            case "kitchen-sink": "水槽包"
            case "lightweight": "轻量"
            case "simplistic": "简洁"
            case "tweaks": "改良"
            case "8x-": "极简"
            case "16x": "16x"
            case "32x": "32x"
            case "48x": "48x"
            case "64x": "64x"
            case "128x": "128x"
            case "256x": "256x"
            case "512x+": "超高清"
            case "audio": "含声音"
            case "fonts": "含字体"
            case "models": "含模型"
            case "gui": "含 UI"
            case "locale": "含语言"
            case "core-shaders": "核心着色器"
            case "modded": "兼容 Mod"
            case "fantasy": "幻想风"
            case "semi-realistic": "半写实风"
            case "cartoon": "卡通风"
            case "colored-lighting": "彩色光照"
            case "path-tracing": "路径追踪"
            case "pbr": "PBR"
            case "reflections": "反射"
            case "iris": "Iris"
            case "optifine": "OptiFine"
            case "vanilla": "原版可用"
            default: nil
            }
            if let tag = tag {
                self.tags.append(tag)
            }
        }
        
        if var supportedVersions = supportedVersions {
            if loaders.count == 1 {
                self.supportDescription.append("仅 \(self.loaders.first!.rawValue.capitalized)")
            } else if loaders.count < 3 {
                self.supportDescription.append(self.loaders.map { $0.rawValue.capitalized }.joined(separator: " / "))
            }
            
            if !self.supportDescription.isEmpty { self.supportDescription.append(" ") }
            supportedVersions.removeAll(where: { $0.starts(with: "3D-Shareware") }) // 笑点解析: 3D-Shareware-v1.34 识别成 1.34
            self.supportDescription.append(ModSummary.describeGameVersions(
                gameVersions: Set(supportedVersions
                    .filter { MinecraftVersion(displayName: $0).type == .release}
                    .map { Int($0.split(separator: ".")[1])! }).sorted(by: { $0 > $1 }),
                mcVersionHighest: Int(DataManager.shared.versionManifest!.latest.release.split(separator: ".")[1])!)
            )
        }
        
        self.downloads = formatNumber(downloads)
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .full
        self.lastUpdate = formatter.localizedString(for: lastUpdate, relativeTo: Date()).replacingOccurrences(of: "(\\d+)", with: " $1 ", options: .regularExpression)
        
        if let iconUrl = iconUrl {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: iconUrl)
                    if let nsImage = NSImage(data: data) {
                        self.icon = Image(nsImage: nsImage)
                    }
                } catch {
                    self.icon = Image("ModIconPlaceholder")
                }
            }
        } else {
            self.icon = Image("ModIconPlaceholder")
        }
    }
    
    func formatNumber(_ num: Int) -> String {
        let absNum = abs(num)
        let sign = num < 0 ? "-" : ""
        let numDouble = Double(absNum)
        
        if absNum >= 100_000_000 {
            let value = numDouble / 100_000_000
            return String(format: "%@%.2f 亿", sign, value)
        } else if absNum >= 10_000 {
            let value = numDouble / 10_000
            return String(format: "%@%.0f 万", sign, value)
        } else {
            return "\(num)"
        }
    }
    
    private static func describeGameVersions(gameVersions: [Int]?, mcVersionHighest: Int) -> String {
        guard let gameVersions = gameVersions, !gameVersions.isEmpty else {
            return "仅快照版本"
        }
        
        var spaVersions: [String] = []
        var isOld = false
        var i = 0
        let count = gameVersions.count
        
        while i < count {
            let startVersion = gameVersions[i]
            var endVersion = startVersion
            
            if startVersion < 10 {
                if !spaVersions.isEmpty && !isOld {
                    break
                } else {
                    isOld = true
                }
            }
            
            var ii = i + 1
            while ii < count && gameVersions[ii] == endVersion - 1 {
                endVersion = gameVersions[ii]
                i = ii
                ii += 1
            }
            
            if startVersion == endVersion {
                spaVersions.append("1.\(startVersion)")
            } else if mcVersionHighest > -1 && startVersion >= mcVersionHighest {
                if endVersion < 10 {
                    spaVersions.removeAll()
                    spaVersions.append("全版本")
                    break
                } else {
                    spaVersions.append("1.\(endVersion)+")
                }
            } else if endVersion < 10 {
                spaVersions.append("1.\(startVersion)-")
                break
            } else if startVersion - endVersion == 1 {
                spaVersions.append("1.\(startVersion), 1.\(endVersion)")
            } else {
                spaVersions.append("1.\(startVersion)~1.\(endVersion)")
            }
            
            i += 1
        }
        
        return spaVersions.joined(separator: ", ")
    }
    
    public func getVersions() -> ModVersionMap? {
        if versions == nil {
            Task {
                self.versions = await self.loadVersions()
                debug("正在获取 \(slug) 的依赖项")
                if let data = try? await AF.request(
                    "https://api.modrinth.com/v2/project/\(self.slug)/dependencies"
                ).serializingResponse(using: .data).value,
                   let json = try? JSON(data: data) {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    self.dependencies.removeAll()
                    for project in json["projects"].arrayValue {
                        let slug = project["slug"].stringValue
                        let dependency = ModDependency(
                            type: .init(rawValue: project["client_side"].stringValue)!,
                            summary: ModSummary(
                                slug: slug,
                                title: project["title"].stringValue,
                                description: project["description"].stringValue,
                                categories: project["categories"].arrayValue.map { $0.stringValue },
                                supportedVersions: nil,
                                downloads: project["downloads"].intValue,
                                lastUpdate: formatter.date(from: project["updated"].stringValue)!,
                                infoUrl: URL(string: "https://modrinth.com/mod/\(slug)")!,
                                iconUrl: URL(string: project["icon_url"].stringValue),
                                loadVersions: { await ModrinthModSearcher.default.getVersions(slug) }
                            )
                        )
                        self.dependencies.append(dependency)
                    }
                }
            }
        }
        
        return versions
    }
}

public protocol ModSearching {
    func search(query: String?, version: MinecraftVersion?) async -> [ModSummary]
}

public class ModrinthModSearcher: ModSearching {
    public static let `default` = ModrinthModSearcher()
    
    @MainActor
    public func getFromJson(_ mod: JSON) -> ModSummary {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return ModSummary(
            slug: mod["slug"].stringValue,
            title: mod["title"].stringValue,
            description: mod["description"].stringValue,
            categories: mod["display_categories"].arrayValue.map { $0.stringValue },
            supportedVersions: (mod["game_versions"].array ?? mod["versions"].arrayValue).map { $0.stringValue },
            downloads: mod["downloads"].intValue,
            lastUpdate: formatter.date(from: mod["date_modified"].string ?? mod["updated"].stringValue)!,
            infoUrl: URL(string: "https://modrinth.com/mod/\(mod["slug"].stringValue)")!,
            iconUrl: URL(string: mod["icon_url"].stringValue),
            loadVersions: { await self.getVersions(mod["slug"].stringValue) }
        )
    }
    
    public func search(query: String? = nil, version: MinecraftVersion? = nil) async -> [ModSummary] {
        var facets = [
            ["project_type:mod"],
        ]
        
        if let version = version {
            facets.append(["version:\(version.displayName)"])
        }
        
        let facetsData = try! JSONSerialization.data(withJSONObject: facets)
        let facetsString = String(data: facetsData, encoding: .utf8)!
        
        if let data = try? await AF.request(
            "https://api.modrinth.com/v2/search",
            method: .get,
            parameters: [
                "query": query ?? "",
                "facets": facetsString,
                "limit": 40
            ],
            encoding: URLEncoding.default
        ).serializingResponse(using: .data).value,
           let json = try? JSON(data: data) {
            let mods = json["hits"].arrayValue
            var result: [ModSummary] = []
            for mod in mods {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                result.append(await getFromJson(mod))
            }
            return result
        }
        return []
    }
    
    public func getVersions(_ slug: String) async -> ModVersionMap {
        if let data = try? await AF.request(
            "https://api.modrinth.com/v2/project/\(slug)/version"
        ).serializingResponse(using: .data).value,
           let json = try? JSON(data: data) {
            var versions: ModVersionMap = [:]
            
            for version in json.arrayValue {
                let key = ModPlatformKey(
                    loader: ClientBrand(rawValue: version["loaders"].arrayValue.first!.stringValue) ?? .vanilla,
                    minecraftVersion: MinecraftVersion(displayName: version["game_versions"].arrayValue.first!.stringValue)
                )
                
                let modVersion = await MainActor.run {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    
                    return ModVersion(
                        name: version["name"].stringValue,
                        version: version["version_number"].stringValue,
                        releaseDate: formatter.date(from: version["date_published"].stringValue)!,
                        type: version["version_type"].stringValue,
                        downloadUrl: version["files"].arrayValue.first!["url"].url!,
                        filename: version["files"].arrayValue.first!["filename"].stringValue.removingPercentEncoding!
                    )
                }
                if versions[key] == nil {
                    versions[key] = []
                }
                versions[key]!.append(modVersion)
            }
            
            return versions
        }
        return [:]
    }
}

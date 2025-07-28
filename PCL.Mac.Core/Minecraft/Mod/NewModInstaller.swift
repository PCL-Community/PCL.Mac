//
//  NewModInstaller.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/27.
//

import Foundation
import SwiftyJSON

public typealias NewModVersionMap = [ModPlatformKey: [NewModVersion]]

public class NewModDependency: Hashable, Identifiable, Equatable {
    public enum DependencyType: String {
        case required, optional, unsupported, unknown
    }
    
    public let summary: NewModSummary
    public let type: DependencyType
    
    init(summary: NewModSummary, type: DependencyType) {
        self.summary = summary
        self.type = type
    }
    
    public let id: UUID = .init()
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: NewModDependency, rhs: NewModDependency) -> Bool { lhs.id == rhs.id }
}

public class NewModVersion: Hashable, Identifiable, Equatable {
    public let name: String
    public let versionNumber: String
    public let type: String
    public let downloads: Int
    public let updateDate: Date
    public let gameVersions: [MinecraftVersion]
    public let loaders: [ClientBrand]
    public let dependencies: [NewModDependency]
    
    public init(name: String, versionNumber: String, type: String, downloads: Int, updateDate: Date, gameVersions: [MinecraftVersion], loaders: [ClientBrand], dependencies: [NewModDependency]) {
        self.name = name
        self.versionNumber = versionNumber
        self.type = type
        self.downloads = downloads
        self.updateDate = updateDate
        self.gameVersions = gameVersions
        self.loaders = loaders
        self.dependencies = dependencies
    }
    
    public let id: UUID = .init()
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: NewModVersion, rhs: NewModVersion) -> Bool { lhs.id == rhs.id }
}

public class NewModSummary: Hashable, Identifiable, Equatable, ObservableObject {
    public let modId: String
    public let name: String
    public let description: String
    public let lastUpdate: Date
    public let downloadCount: Int
    public let gameVersions: [MinecraftVersion]
    public let loaders: [ClientBrand]
    public let tags: [String]
    public let iconUrl: URL?
    public let infoUrl: URL
    public let versions: [String]? // 只有通过搜索创建时这个变量的值才为 nil
    
    init(modId: String, name: String, description: String, lastUpdate: Date, downloadCount: Int, gameVersions: [MinecraftVersion], categories: [String], iconUrl: URL?, infoUrl: URL, versions: [String]?) {
        self.modId = modId
        self.name = name
        self.description = description
        self.lastUpdate = lastUpdate
        self.downloadCount = downloadCount
        self.gameVersions = gameVersions
        self.iconUrl = iconUrl
        self.infoUrl = infoUrl
        self.versions = versions
        
        var loaders: [ClientBrand] = []
        var tags: [String] = []
        for category in categories {
            if let loader = ClientBrand(rawValue: category) {
                loaders.append(loader)
                continue
            }
            tags.append(category)
        }
        self.loaders = loaders
        self.tags = tags
    }
    
    convenience init(json: JSON) {
        self.init(
            modId: json["slug"].stringValue,
            name: json["title"].stringValue,
            description: json["description"].stringValue,
            lastUpdate: ModSearcher.shared.dateFormatter.date(from: json["date_modified"].string ?? json["updated"].stringValue)!,
            downloadCount: json["downloads"].intValue,
            gameVersions: (json["game_versions"].array ?? json["versions"].arrayValue).map { MinecraftVersion(displayName: $0.stringValue) },
            categories: json["categories"].arrayValue.union(json["loaders"].arrayValue).map { $0.stringValue },
            iconUrl: json["icon_url"].url,
            infoUrl: URL(string: "https://modrinth.com/mod/\(json["slug"].stringValue)")!,
            versions: json["versions"].array.map { $0.map { $0.stringValue } } // 若 versions 存在，传入 versions 的 [String] 形式，否则传入 nil
        )
    }
    
    public let id: UUID = .init()
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: NewModSummary, rhs: NewModSummary) -> Bool { lhs.id == rhs.id }
}

public class ModSearcher {
    public static let shared = ModSearcher()
    
    fileprivate var dateFormatter: ISO8601DateFormatter
    private var dependencyCache: [String: NewModSummary?] = [:]
    
    private init() {
        self.dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }
    
    public func get(_ id: String) async throws -> NewModSummary {
        return .init(json: try await Requests.get("https://api.modrinth.com/v2/project/\(id)").getJSONOrThrow())
    }
    
    private func getDependencies(_ json: JSON) async -> [NewModDependency] {
        var dependencies: [NewModDependency] = []
        for dependency in json["dependencies"].arrayValue {
            guard let projectId = dependency["project_id"].string else { continue }
            guard dependency["dependency_type"] != "incompatible" else { continue }
            
            let dependencySummary: NewModSummary?
            if let cache = dependencyCache[projectId] {
                dependencySummary = cache
            } else {
                dependencySummary = try? await get(projectId)
                dependencyCache[projectId] = dependencySummary
            }
            
            if let dependencySummary = dependencySummary {
                dependencies.append(
                    .init(
                        summary: dependencySummary,
                        type: .init(rawValue: dependency["dependency_type"].stringValue) ?? .required
                    )
                )
            }
        }
        return dependencies
    }
    
    public func getVersion(_ version: String) async throws -> NewModVersion {
        let json = try await Requests.get("https://api.modrinth.com/v2/version/\(version)").getJSONOrThrow()
        
        return .init(
            name: json["name"].stringValue,
            versionNumber: json["version_number"].stringValue,
            type: json["version_type"].stringValue,
            downloads: json["downloads"].intValue,
            updateDate: dateFormatter.date(from: json["date_published"].stringValue)!,
            gameVersions: json["game_versions"].arrayValue.map { MinecraftVersion(displayName: $0.stringValue) },
            loaders: json["loaders"].arrayValue.map { ClientBrand(rawValue: $0.stringValue) ?? .vanilla },
            dependencies: await getDependencies(json)
        )
    }
    
    public func getVersionMap(id: String) async throws -> NewModVersionMap {
        let json = try await Requests.get("https://api.modrinth.com/v2/project/\(id)/version").getJSONOrThrow()
        var versionMap: NewModVersionMap = [:]
        
        for version in json.arrayValue {
            let version = NewModVersion(
                name: version["name"].stringValue,
                versionNumber: version["version_number"].stringValue,
                type: version["version_type"].stringValue,
                downloads: version["downloads"].intValue,
                updateDate: dateFormatter.date(from: version["date_published"].stringValue)!,
                gameVersions: version["game_versions"].arrayValue.map { MinecraftVersion(displayName: $0.stringValue) },
                loaders: version["loaders"].arrayValue.map { ClientBrand(rawValue: $0.stringValue) ?? .vanilla },
                dependencies: await getDependencies(version)
            )
            
            for gameVersion in version.gameVersions {
                for loader in version.loaders {
                    let key = ModPlatformKey(loader: loader, minecraftVersion: gameVersion)
                    if versionMap[key] == nil {
                        versionMap[key] = []
                    }
                    versionMap[key]!.append(version)
                }
            }
        }
        
        return versionMap
    }
    
    // 模组搜索界面调用
    // 不通过此函数获取模组版本列表
    public func search(query: String, version: MinecraftVersion? = nil, limit: Int = 40) async throws -> [NewModSummary] {
        var facets = [
            ["project_type:mod"],
        ]
        
        if let version = version {
            facets.append(["version:\(version.displayName)"])
        }
        
        let facetsData = try! JSONSerialization.data(withJSONObject: facets)
        let facetsString = String(data: facetsData, encoding: .utf8)!
        
        let json = try await Requests.get(
            "https://api.modrinth.com/v2/search",
            body: [
                "query": query,
                "facets": facetsString,
                "limit": limit
            ],
            encodeMethod: .urlEncoded
        ).getJSONOrThrow()
        
        return json["hits"].arrayValue.map(NewModSummary.init(json:))
    }
}

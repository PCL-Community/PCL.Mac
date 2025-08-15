//
//  ProjectSummary.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/14.
//

import Foundation

import SwiftyJSON

public struct ProjectPlatformKey: Hashable, Comparable {
    public static func < (lhs: ProjectPlatformKey, rhs: ProjectPlatformKey) -> Bool {
        lhs.minecraftVersion < rhs.minecraftVersion
    }
    
    let loader: ClientBrand
    let minecraftVersion: MinecraftVersion
}

public typealias ProjectVersionMap = [ProjectPlatformKey: [ProjectVersion]]

public extension ProjectVersionMap {
    var gameVersions: [MinecraftVersion] {
        self.keys.map { $0.minecraftVersion }
            .filter { $0.type == .release }
            .sorted(by: >)
    }
    
    var loaders: [ClientBrand] {
        Array(Set(self.keys.map { $0.loader }))
            .sorted(by: { $0.index < $1.index})
    }
}

public class ProjectDependency: Hashable, Identifiable, Equatable {
    public enum DependencyType: String {
        case required, optional, unsupported, unknown
    }
    
    public let summary: ProjectSummary
    public let versionId: String?
    public let type: DependencyType
    
    init(summary: ProjectSummary, versionId: String?, type: DependencyType) {
        self.summary = summary
        self.versionId = versionId
        self.type = type
    }
    
    public let id: UUID = .init()
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: ProjectDependency, rhs: ProjectDependency) -> Bool { lhs.id == rhs.id }
}

public class ProjectVersion: Hashable, Identifiable, Equatable {
    public let projectType: ProjectType
    public let projectId: String
    public let name: String
    public let versionNumber: String
    public let type: String
    public let downloads: Int
    public let updateDate: Date
    public let gameVersions: [MinecraftVersion]
    public let loaders: [ClientBrand]
    public let dependencies: [ProjectDependency]
    public let downloadURL: URL
    
    public init(projectType: ProjectType, projectId: String, name: String, versionNumber: String, type: String, downloads: Int, updateDate: Date, gameVersions: [MinecraftVersion], loaders: [ClientBrand], dependencies: [ProjectDependency], downloadURL: URL) {
        self.projectType = projectType
        self.projectId = projectId
        self.name = name
        self.versionNumber = versionNumber
        self.type = type
        self.downloads = downloads
        self.updateDate = updateDate
        self.gameVersions = gameVersions
        self.loaders = loaders
        self.dependencies = dependencies
        self.downloadURL = downloadURL
    }
    
    public let id: UUID = .init()
    public func hash(into hasher: inout Hasher) { hasher.combine(projectId) }
    public static func == (lhs: ProjectVersion, rhs: ProjectVersion) -> Bool { lhs.projectId == rhs.projectId }
}

public class ProjectSummary: Hashable, Identifiable, Equatable {
    public let type: ProjectType
    public let projectId: String
    public let modId: String
    public let name: String
    public let description: String
    public let lastUpdate: Date
    public let downloadCount: Int
    public let gameVersions: [MinecraftVersion]
    public let loaders: [ClientBrand]
    public let tags: [String]
    public let iconURL: URL?
    public let infoURL: URL
    public let versions: [String]? // 只有通过搜索创建时这个变量的值才为 nil
    
    init(type: ProjectType, projectId: String, modId: String, name: String, description: String, lastUpdate: Date, downloadCount: Int, gameVersions: [MinecraftVersion], categories: [String], iconURL: URL?, infoURL: URL, versions: [String]?) {
        self.type = type
        self.projectId = projectId
        self.modId = modId
        self.name = name
        self.description = description
        self.lastUpdate = lastUpdate
        self.downloadCount = downloadCount
        self.gameVersions = gameVersions
        self.iconURL = iconURL
        self.infoURL = infoURL
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
            type: ProjectType(rawValue: json["project_type"].stringValue) ?? .mod,
            projectId: json["project_id"].string ?? json["id"].stringValue,
            modId: json["slug"].stringValue,
            name: json["title"].stringValue,
            description: json["description"].stringValue,
            lastUpdate: ModrinthProjectSearcher.shared.dateFormatter.date(from: json["date_modified"].string ?? json["updated"].stringValue)!,
            downloadCount: json["downloads"].intValue,
            gameVersions: (json["game_versions"].array ?? json["versions"].arrayValue).map { MinecraftVersion(displayName: $0.stringValue) },
            categories: json["categories"].arrayValue.union(json["loaders"].arrayValue).map { $0.stringValue },
            iconURL: json["icon_url"].url,
            infoURL: URL(string: "https://modrinth.com/mod/\(json["slug"].stringValue)")!,
            versions: json["versions"].array.map { $0.map { $0.stringValue } } // 若 versions 存在，传入 versions 的 [String] 形式，否则传入 nil
        )
    }
    
    public let id: UUID = .init()
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: ProjectSummary, rhs: ProjectSummary) -> Bool { lhs.id == rhs.id }
}

//
//  ResourcePackSearcher.swift
//  PCL.Mac
//
//  Created by DeepChTi on 2025/8/12.
//

import SwiftUI
import SwiftyJSON

public struct ResourcePackPlatformKey: Hashable, Comparable {
    public static func < (lhs: ResourcePackPlatformKey, rhs: ResourcePackPlatformKey) -> Bool {
        lhs.minecraftVersion < rhs.minecraftVersion
    }
    
    let minecraftVersion: MinecraftVersion
    
    public static func == (lhs: ResourcePackPlatformKey, rhs: ResourcePackPlatformKey) -> Bool {
        lhs.minecraftVersion == rhs.minecraftVersion
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(minecraftVersion)
    }
}

public typealias ResourcePackVersionMap = [ResourcePackPlatformKey: [ResourcePackVersion]]

public class ResourcePackVersion: Hashable, Identifiable, Equatable {
    public let projectId: String
    public let name: String
    public let versionNumber: String
    public let type: String
    public let downloads: Int
    public let updateDate: Date
    public let gameVersions: [MinecraftVersion]
    public let downloadURL: URL
    
    public init(projectId: String, name: String, versionNumber: String, type: String, downloads: Int, updateDate: Date, gameVersions: [MinecraftVersion], downloadURL: URL) {
        self.projectId = projectId
        self.name = name
        self.versionNumber = versionNumber
        self.type = type
        self.downloads = downloads
        self.updateDate = updateDate
        self.gameVersions = gameVersions
        self.downloadURL = downloadURL
    }
    
    public let id: UUID = .init()
    public func hash(into hasher: inout Hasher) { hasher.combine(projectId) }
    public static func == (lhs: ResourcePackVersion, rhs: ResourcePackVersion) -> Bool { lhs.projectId == rhs.projectId }
}

public class ResourcePackSummary: Hashable, Identifiable, Equatable {
    public let projectId: String
    public let resourcePackId: String
    public let name: String
    public let description: String
    public let lastUpdate: Date
    public let downloadCount: Int
    public let gameVersions: [MinecraftVersion]
    public let tags: [String]
    public let iconURL: URL?
    public let infoURL: URL
    public let versions: [String]?
    
    init(projectId: String, resourcePackId: String, name: String, description: String, lastUpdate: Date, downloadCount: Int, gameVersions: [MinecraftVersion], categories: [String], iconURL: URL?, infoURL: URL, versions: [String]?) {
        self.projectId = projectId
        self.resourcePackId = resourcePackId
        self.name = name
        self.description = description
        self.lastUpdate = lastUpdate
        self.downloadCount = downloadCount
        self.gameVersions = gameVersions
        self.iconURL = iconURL
        self.infoURL = infoURL
        self.versions = versions
        self.tags = categories
    }
    
    convenience init(json: JSON) {
        self.init(
            projectId: json["project_id"].string ?? json["id"].stringValue,
            resourcePackId: json["slug"].stringValue,
            name: json["title"].stringValue,
            description: json["description"].stringValue,
            lastUpdate: ResourcePackSearcher.shared.dateFormatter.date(from: json["date_modified"].string ?? json["updated"].stringValue)!,
            downloadCount: json["downloads"].intValue,
            gameVersions: (json["game_versions"].array ?? json["versions"].arrayValue).map { MinecraftVersion(displayName: $0.stringValue) },
            categories: json["categories"].arrayValue.map { $0.stringValue },
            iconURL: json["icon_url"].url,
            infoURL: URL(string: "https://modrinth.com/resourcepack/\(json["slug"].stringValue)")!,
            versions: json["versions"].array?.map { $0.stringValue }
        )
    }
    
    public let id: UUID = .init()
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: ResourcePackSummary, rhs: ResourcePackSummary) -> Bool { lhs.id == rhs.id }
}

public class ResourcePackSearcher {
    public static let shared = ResourcePackSearcher()
    
    fileprivate var dateFormatter: ISO8601DateFormatter
    
    private init() {
        self.dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }
    
    public func get(_ id: String) async throws -> ResourcePackSummary {
        return .init(json: try await Requests.get("https://api.modrinth.com/v2/project/\(id)", ignoredFailureStatusCodes: [404]).getJSONOrThrow())
    }
    
    public func getVersion(_ version: String) async throws -> ResourcePackVersion {
        let json = try await Requests.get("https://api.modrinth.com/v2/version/\(version)").getJSONOrThrow()
        
        return .init(
            projectId: json["project_id"].stringValue,
            name: json["name"].stringValue,
            versionNumber: json["version_number"].stringValue,
            type: json["version_type"].stringValue,
            downloads: json["downloads"].intValue,
            updateDate: dateFormatter.date(from: json["date_published"].stringValue)!,
            gameVersions: json["game_versions"].arrayValue.map { MinecraftVersion(displayName: $0.stringValue) },
            downloadURL: json["files"].arrayValue.first!["url"].url!
        )
    }
    
    public func getVersionMap(id: String) async throws -> ResourcePackVersionMap {
        let json = try await Requests.get("https://api.modrinth.com/v2/project/\(id)/version").getJSONOrThrow()
        var versionMap: ResourcePackVersionMap = [:]
        
        for version in json.arrayValue {
            let version = ResourcePackVersion(
                projectId: version["project_id"].stringValue,
                name: version["name"].stringValue,
                versionNumber: version["version_number"].stringValue,
                type: version["version_type"].stringValue,
                downloads: version["downloads"].intValue,
                updateDate: dateFormatter.date(from: version["date_published"].stringValue)!,
                gameVersions: version["game_versions"].arrayValue.map { MinecraftVersion(displayName: $0.stringValue) },
                downloadURL: version["files"].arrayValue.first!["url"].url!
            )
            
            for gameVersion in version.gameVersions {
                let key = ResourcePackPlatformKey(minecraftVersion: gameVersion)
                if versionMap[key] == nil {
                    versionMap[key] = []
                }
                versionMap[key]!.append(version)
            }
        }
        
        return versionMap
    }
    
    public func search(query: String, version: MinecraftVersion? = nil, limit: Int = 40) async throws -> [ResourcePackSummary] {
        var facets = [
            ["project_type:resourcepack"],
        ]
        
        if let version = version {
            facets.append(["versions:\(version.displayName)"])
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
        
        return json["hits"].arrayValue.map { ResourcePackSummary(json: $0) }
    }
}

public class ResourcePackInstallTask: InstallTask {
    @Published public var state: InstallState = .waiting
    
    public let instance: MinecraftInstance
    private let resourcePacks: [ResourcePackVersion]
    
    init(instance: MinecraftInstance, resourcePacks: [ResourcePackVersion]) {
        self.instance = instance
        self.resourcePacks = resourcePacks
        super.init()
        self.totalFiles = resourcePacks.count
        self.remainingFiles = totalFiles
    }
    
    public override func start() {
        Task {
            await MainActor.run {
                self.state = .inprogress
            }
            
            await withCheckedContinuation { continuation in
                let downloader = ProgressiveDownloader(
                    task: self,
                    urls: resourcePacks.map { $0.downloadURL },
                    destinations: resourcePacks.map { instance.runningDirectory.appending(path: "resourcepacks").appending(path: $0.downloadURL.lastPathComponent) },
                    skipIfExists: true,
                    completion: continuation.resume
                )
                downloader.start()
            }
            self.callback?()
        }
    }
    
    public override func getInstallStates() -> [InstallStage : InstallState] { [.resourcePacks : state] }
    public override func getTitle() -> String { "资源包下载" }
}
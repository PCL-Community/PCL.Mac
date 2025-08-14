//
//  ModrinthProjectSearcher.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/12.
//

import Foundation
import SwiftyJSON

public class ModrinthProjectSearcher {
    public static let shared: ModrinthProjectSearcher = .init()
    
    public var dateFormatter: ISO8601DateFormatter
    private var dependencyCache: [String: ProjectSummary?] = [:]
    
    private init() {
        self.dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }
    
    public func get(_ id: String) async throws -> ProjectSummary {
        return .init(json: try await Requests.get("https://api.modrinth.com/v2/project/\(id)", ignoredFailureStatusCodes: [404]).getJSONOrThrow())
    }
    
    private func getDependencies(_ json: JSON) async -> [ProjectDependency] {
        var dependencies: [ProjectDependency] = []
        for dependency in json["dependencies"].arrayValue {
            guard let projectId = dependency["project_id"].string else { continue }
            guard dependency["dependency_type"] != "incompatible" else { continue }
            
            let dependencySummary: ProjectSummary?
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
                        versionId: dependency["version_id"].string,
                        type: .init(rawValue: dependency["dependency_type"].stringValue) ?? .required
                    )
                )
            }
        }
        return dependencies
    }
    
    public func getVersion(_ version: String) async throws -> ProjectVersion {
        let json = try await Requests.get("https://api.modrinth.com/v2/version/\(version)").getJSONOrThrow()
        
        return .init(
            projectId: json["project_id"].stringValue,
            name: json["name"].stringValue,
            versionNumber: json["version_number"].stringValue,
            type: json["version_type"].stringValue,
            downloads: json["downloads"].intValue,
            updateDate: dateFormatter.date(from: json["date_published"].stringValue)!,
            gameVersions: json["game_versions"].arrayValue.map { MinecraftVersion(displayName: $0.stringValue) },
            loaders: json["loaders"].arrayValue.map { ClientBrand(rawValue: $0.stringValue) ?? .vanilla },
            dependencies: await getDependencies(json),
            downloadURL: json["files"].arrayValue.first!["url"].url!
        )
    }
    
    public func getVersionMap(id: String) async throws -> ProjectVersionMap {
        let json = try await Requests.get("https://api.modrinth.com/v2/project/\(id)/version").getJSONOrThrow()
        var versionMap: ProjectVersionMap = [:]
        
        for version in json.arrayValue {
            let version = ProjectVersion(
                projectId: version["project_id"].stringValue,
                name: version["name"].stringValue,
                versionNumber: version["version_number"].stringValue,
                type: version["version_type"].stringValue,
                downloads: version["downloads"].intValue,
                updateDate: dateFormatter.date(from: version["date_published"].stringValue)!,
                gameVersions: version["game_versions"].arrayValue.map { MinecraftVersion(displayName: $0.stringValue) },
                loaders: version["loaders"].arrayValue.map { ClientBrand(rawValue: $0.stringValue) ?? .vanilla },
                dependencies: await getDependencies(version),
                downloadURL: version["files"].arrayValue.first!["url"].url!
            )
            
            for gameVersion in version.gameVersions {
                for loader in version.loaders {
                    let key = ProjectPlatformKey(loader: loader, minecraftVersion: gameVersion)
                    if versionMap[key] == nil {
                        versionMap[key] = []
                    }
                    versionMap[key]!.append(version)
                }
            }
        }
        
        return versionMap
    }
    
    public func search(type: String, query: String, version: MinecraftVersion? = nil, loader: ClientBrand? = nil, limit: Int = 40) async throws -> [ProjectSummary] {
        var facets = [
            ["project_type:mod"],
        ]
        
        if let version = version {
            facets.append(["versions:\(version.displayName)"])
        }
        if let loader = loader {
            facets.append(["categories:\(loader.rawValue)"])
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
        
        return json["hits"].arrayValue.map(ProjectSummary.init(json:))
    }
}

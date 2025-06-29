//
//  NewClientManifest.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/6/14.
//

//
//  ClientManifest.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/5/20.
//

import Foundation
import SwiftyJSON

public class ClientManifest {
    public let id: String
    public let mainClass: String
    public let type: String
    public let assetIndex: AssetIndex
    public let assets: String
    public let downloads: [String: DownloadInfo]
    public let libraries: [Library]
    public let arguments: Arguments?
    public let minecraftArguments: String?
    public let javaVersion: Int?

    public init(json: JSON) {
        self.id = json["id"].stringValue
        self.mainClass = json["mainClass"].stringValue
        self.type = json["type"].stringValue
        self.assets = json["assets"].stringValue
        self.assetIndex = AssetIndex(json: json["assetIndex"])
        self.downloads = json["downloads"].dictionaryValue.mapValues(DownloadInfo.init(json:))
        self.libraries = json["libraries"].arrayValue.map(Library.init(json:))
        self.arguments = json["arguments"].exists() ? Arguments(json: json["arguments"]) : nil
        self.minecraftArguments = json["minecraftArguments"].string
        self.javaVersion = json["javaVersion"]["majorVersion"].int
    }

    public class AssetIndex {
        public let id: String
        public let sha1: String
        public let size: Int
        public let totalSize: Int
        public let url: String
        public init(json: JSON) {
            id = json["id"].stringValue
            sha1 = json["sha1"].stringValue
            size = json["size"].intValue
            totalSize = json["totalSize"].intValue
            url = json["url"].stringValue
        }
    }

    public class DownloadInfo {
        public let path: String
        public let sha1: String?
        public let size: Int?
        public var url: String
        
        public init(json: JSON) {
            path = json["path"].stringValue
            sha1 = json["sha1"].string
            size = json["size"].int
            url = json["url"].stringValue
        }
        
        init(path: String, sha1: String? = nil, size: Int? = nil, url: String) {
            self.path = path
            self.sha1 = sha1
            self.size = size
            self.url = url
        }
    }

    public class Library: Hashable {
        public let name: String
        private let split: [String]
        public var groupId: String
        public var artifactId: String
        public var version: String
        public var classifier: String?
        public let rules: [Rule]
        public let natives: [String: String]
        public let artifact: DownloadInfo?
        public let classifiers: [String: DownloadInfo]

        public init(json: JSON) {
            name = json["name"].stringValue
            split = name.split(separator: ":").map(String.init)
            groupId = split[0]
            artifactId = split[1]
            version = split[2]
            classifier = split.count >= 4 ? split[3] : nil
            
            if json["url"].exists() { // Fabric 依赖
                debug("检测到 Fabric 依赖 \(json["name"].stringValue)")
                self.rules = []
                self.classifiers = [:]
                self.natives = [:]
                let path = Util.toPath(mavenCoordinate: name)
                self.artifact = DownloadInfo(path: path, url: URL(string: json["url"].stringValue)!.appending(path: path).absoluteString)
            } else {
                rules = json["rules"].arrayValue.map { Rule(json: $0) }
                natives = json["natives"].dictionaryObject as? [String: String] ?? [:]
                artifact = json["downloads"]["artifact"].exists() ? DownloadInfo(json: json["downloads"]["artifact"]) : nil
                if let cls = json["downloads"]["classifiers"].dictionary {
                    var result: [String: DownloadInfo] = [:]
                    for (k, v) in cls {
                        result[k] = DownloadInfo(json: v)
                    }
                    classifiers = result
                } else {
                    classifiers = [:]
                }
            }
        }
        
        public func getNativeArtifact() -> DownloadInfo? {
            let key = natives["osx"]
            guard let key, let nativeDl = classifiers[key] else { return nil }
            return nativeDl
        }
        
        public static func ==(lhs: Library, rhs: Library) -> Bool { lhs.name == rhs.name }
        public func hash(into hasher: inout Hasher) { hasher.combine(name) }
    }

    public class Arguments {
        public let game: [GameArgument]
        public let jvm: [JvmArgument]

        public init(json: JSON) {
            game = json["game"].arrayValue.map { GameArgument(json: $0) }
            jvm = json["jvm"].arrayValue.map { JvmArgument(json: $0) }
        }
        
        init(game: [GameArgument], jvm: [JvmArgument]) {
            self.game = game
            self.jvm = jvm
        }
        
        public func getAllowedGameArguments() -> [String] {
            let filtered = game.filter { $0.match() }
            var arguments: [String] = []
            for arg in filtered {
                arguments.append(contentsOf: arg.values())
            }
            return arguments
        }
        public func getAllowedJVMArguments() -> [String] {
            let filtered = jvm.filter { $0.match() }
            var arguments: [String] = []
            for arg in filtered { arguments.append(contentsOf: arg.values()) }
            return arguments
        }

        public class GameArgument {
            public let string: String?
            public let rules: RuleTag?

            public init(json: JSON) {
                if let str = json.string { string = str; rules = nil }
                else { string = nil; rules = RuleTag(json: json) }
            }
            public func match() -> Bool { rules?.match() ?? true }
            public func values() -> [String] {
                if let string { return [string] }
                if let rules, rules.match() { return rules.value }
                return []
            }
        }
        
        public class JvmArgument {
            public let string: String?
            public let rules: RuleTag?

            public init(json: JSON) {
                if let str = json.string { string = str; rules = nil }
                else { string = nil; rules = RuleTag(json: json) }
            }
            public func match() -> Bool { rules?.match() ?? true }
            public func values() -> [String] {
                if let string { return [string] }
                if let rules, rules.match() { return rules.value }
                return []
            }
        }
        
        public class RuleTag {
            public let rules: [Rule]
            public let value: [String]
            public init(json: JSON) {
                rules = json["rules"].arrayValue.map { Rule(json: $0) }
                if let str = json["value"].string {
                    value = [str]
                } else if let arr = json["value"].array {
                    value = arr.compactMap { $0.string }
                } else {
                    value = []
                }
            }
            public func match() -> Bool {
                rules.allSatisfy { $0.match() }
            }
        }
    }

    public class Rule {
        public let action: String
        public let os: OSRule?
        public let features: Features?
        public init(json: JSON) {
            action = json["action"].stringValue
            os = json["os"].exists() ? OSRule(json: json["os"]) : nil
            features = json["features"].exists() ? Features(json: json["features"]) : nil
        }
        public func match() -> Bool {
            (os?.match() ?? true) && (features?.match() ?? true) && action == "allow"
        }
        public class OSRule {
            public let name: String?
            public let arch: String?
            public init(json: JSON) {
                name = json["name"].string
                arch = json["arch"].string
            }
            public func match() -> Bool {
                if let name, name != "osx" { return false }
                // TODO: 处理 arch
                return true
            }
        }
        
        public class Features {
            public let isDemoUser: Bool?
            public let hasCustomResolution: Bool?
            public let hasQuickPlaysSupport: Bool?
            public let isQuickPlaySingleplayer: Bool?
            public let isQuickPlayMultiplayer: Bool?
            public let isQuickPlayRealms: Bool?
            public init(json: JSON) {
                isDemoUser = json["is_demo_user"].bool
                hasCustomResolution = json["has_custom_resolution"].bool
                hasQuickPlaysSupport = json["has_quick_plays_support"].bool
                isQuickPlaySingleplayer = json["is_quick_play_singleplayer"].bool
                isQuickPlayMultiplayer = json["is_quick_play_multiplayer"].bool
                isQuickPlayRealms = json["is_quick_play_realms"].bool
            }
            public func match() -> Bool {
                if isDemoUser == true { return false }
                if hasCustomResolution == true { return false }
                if hasQuickPlaysSupport == true { return false }
                if isQuickPlaySingleplayer == true { return false }
                if isQuickPlayMultiplayer == true { return false }
                if isQuickPlayRealms == true { return false }
                return true
            }
        }
    }

    public static func parse(_ data: Data) throws -> ClientManifest {
        let json = try JSON(data: data)
        return ClientManifest(json: json)
    }

    public func getNeededLibraries() -> [Library] {
        getAllowedLibraries().filter { lib in
            return !lib.name.contains("natives") && lib.artifact != nil
        }
    }
    public func getAllowedLibraries() -> [Library] {
        libraries.filter { lib in
            (lib.rules.isEmpty ? true : lib.rules.allSatisfy { $0.match() })
        }
    }
    public func getNeededNatives() -> [Library: DownloadInfo] {
        var result: [Library: DownloadInfo] = [:]
        for lib in getAllowedLibraries() {
            if let artifact = lib.getNativeArtifact() {
                result[lib] = artifact
            } else if let artifact = lib.artifact,
                      lib.name.hasPrefix("org.lwjgl"),
                      lib.name.contains("natives") {
                result[lib] = artifact
            }
        }
        return result
    }
    public func getArguments() -> Arguments {
        if let arguments = self.arguments {
            return arguments
        } else if let minecraftArguments = self.minecraftArguments {
            let gameArgs = minecraftArguments.split(separator: " ").map { Arguments.GameArgument(json: JSON(stringLiteral: String($0))) }
            let jvmArgs: [Arguments.JvmArgument] = [
                "-XX:+UnlockExperimentalVMOptions", "-XX:+UseG1GC", "-XX:-UseAdaptiveSizePolicy", "-XX:-OmitStackTraceInFastThrow",
                "-Djava.library.path=${natives_directory}",
                "-Dorg.lwjgl.system.SharedLibraryExtractPath=${natives_directory}",
                "-Dio.netty.native.workdir=${natives_directory}",
                "-Djna.tmpdir=${natives_directory}",
                "-cp", "${classpath}"
            ].map { Arguments.JvmArgument(json: JSON(stringLiteral: $0)) }
            return Arguments(game: gameArgs, jvm: jvmArgs)
        } else {
            return Arguments(game: [], jvm: [])
        }
    }
}

//
//  ClientManifest.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/20.
//

import Foundation
import SwiftyJSON

public class ClientManifest {
    public let id: String
    public var mainClass: String
    public let type: String
    public let assetIndex: AssetIndex?
    public let assets: String
    public var libraries: [Library]
    public let arguments: Arguments?
    public var minecraftArguments: String?
    public let javaVersion: Int?
    public let clientDownload: DownloadInfo?
    public let clientMappingsDownload: DownloadInfo?

    private init?(json: JSON) {
        self.id = json["id"].stringValue
        self.mainClass = json["mainClass"].stringValue
        self.type = json["type"].stringValue
        self.assets = json["assets"].stringValue
        self.assetIndex = json["assetIndex"].exists() ? AssetIndex(json: json["assetIndex"]) : nil
        self.libraries = json["libraries"].arrayValue.compactMap(Library.init(json:))
        self.arguments = json["arguments"].exists() ? Arguments(json: json["arguments"]) : nil
        self.minecraftArguments = json["minecraftArguments"].string
        self.javaVersion = json["javaVersion"]["majorVersion"].int
        self.clientDownload = json["downloads"]["client"].exists() ? .init(json: json["downloads"]["client"]) : nil
        self.clientMappingsDownload = json["downloads"]["client_mappings"].exists() ? .init(json: json["downloads"]["client_mappings"]) : nil
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

    public class DownloadInfo: Hashable {
        public var path: String
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
        
        public static func == (lhs: DownloadInfo, rhs: DownloadInfo) -> Bool {
            lhs.path == rhs.path
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(path)
        }
    }

    public class Library: Hashable {
        public var name: String {
            didSet {
                split = name.split(separator: ":").map(String.init)
            }
        }
        private var split: [String]
        public var groupId: String { split[0] }
        public var artifactId: String { split[1] }
        public var version: String { split[2] }
        public var classifier: String? { split.count >= 4 ? split[3] : nil }
        public let rules: [Rule]
        public let natives: [String: String]
        public let artifact: DownloadInfo?
        public let isNativeLibrary: Bool

        public init?(json: JSON) {
            self.name = json["name"].stringValue
            self.split = name.split(separator: ":").map(String.init)
            if split.isEmpty {
                return nil
            }
            
            if !json["downloads"].exists() {
                self.rules = []
                self.natives = [:]
                let path = Util.toPath(mavenCoordinate: name)
                self.artifact = DownloadInfo(
                    path: path,
                    url: (URL(string: json["url"].stringValue) ?? URL(string: "https://bmclapi2.bangbang93.com/maven")!).appending(path: path).absoluteString
                )
            } else {
                if split[1] == "launchwrapper" {
                    self.rules = []
                    self.natives = [:]
                    let path = Util.toPath(mavenCoordinate: name)
                    self.artifact = DownloadInfo(path: path, url: URL(string: "https://libraries.minecraft.net")!.appending(path: path).absoluteString)
                } else {
                    self.rules = json["rules"].arrayValue.map { Rule(json: $0) }
                    self.natives = json["natives"].dictionaryObject as? [String: String] ?? [:]
                    
                    if let classifiers = json["downloads"]["classifiers"].dictionary,
                       let key = natives["osx"],
                       let json = classifiers[key] {
                        self.artifact = DownloadInfo(json: json)
                        self.isNativeLibrary = true
                        return
                    } else {
                        self.artifact = json["downloads"]["artifact"].exists() ? DownloadInfo(json: json["downloads"]["artifact"]) : nil
                    }
                }
            }
            
            self.isNativeLibrary = false
        }
        
        public static func == (lhs: Library, rhs: Library) -> Bool { lhs.name == rhs.name }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
    }

    public class Arguments {
        public var game: [GameArgument]
        public var jvm: [JvmArgument]

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
    
    /// 尝试解析与自动合并客户端清单，不会对实例进行操作
    /// - Parameter url: 清单路径
    /// - Parameter minecraftDirectory: 若需自动合并，该参数的值为实例所在的 minecraft 目录，否则为空
    public static func parse(url: URL, minecraftDirectory: MinecraftDirectory? = nil) throws -> ClientManifest? {
        let data = try FileHandle(forReadingFrom: url).readToEnd() ?? Data()
        let json = try JSON(data: data)
        
        if json["loader"].exists() { // 旧版 PCL.Mac Fabric 安装逻辑
            warn("无法解析旧版 PCL.Mac 安装的 Fabric 版本: \(url.lastPathComponent)")
            return nil
        }
        
    checkParent:
        if let inheritsFrom = json["inheritsFrom"].string,
           let minecraftDirectory = minecraftDirectory {
            let parentURL = minecraftDirectory.versionsURL.appending(path: inheritsFrom).appending(path: "\(inheritsFrom).json")
            
            guard FileManager.default.fileExists(atPath: parentURL.path) else {
                err("\(url.path) 中有 inheritsFrom 字段，但其对应的 JSON 不存在")
                return nil
            }
            
            let parent: ClientManifest
            guard let manifest = ClientManifest(json: json) else { return nil }
            do {
                guard let manifest = try ClientManifest.parse(url: parentURL, minecraftDirectory: minecraftDirectory) else { return nil }
                parent = manifest
            } catch {
                err("无法解析 inheritsFrom: \(error.localizedDescription)")
                break checkParent
            }
            
            return merge(parent: parent, manifest: manifest)
        }
        return ClientManifest(json: json)
    }
    
    private static func merge(parent: ClientManifest, manifest: ClientManifest) -> ClientManifest {
        // 修正 libraries
        ArtifactVersionMapper.map(parent, arch: .x64)
        ArtifactVersionMapper.map(manifest, arch: .x64)
        
        parent.libraries.insert(contentsOf: manifest.libraries, at: 0)
        var librarySet: Set<HashableLibrary> = .init()
        parent.libraries = parent.libraries.filter { librarySet.insert(.init($0)).inserted }
        parent.arguments?.game.append(contentsOf: manifest.arguments?.game ?? [])
        parent.arguments?.jvm.append(contentsOf: manifest.arguments?.jvm ?? [])
        parent.minecraftArguments = manifest.minecraftArguments
        parent.mainClass = manifest.mainClass
        
        return parent
    }

    public func getNeededLibraries() -> [Library] {
        getAllowedLibraries().filter { !$0.isNativeLibrary }
    }
    
    public func getAllowedLibraries() -> [Library] {
        libraries.filter { lib in
            (lib.rules.isEmpty ? true : lib.rules.allSatisfy { $0.match() })
        }
    }
    
    public func getNeededNatives() -> [Library: DownloadInfo] {
        var result: [Library: DownloadInfo] = [:]
        for library in getAllowedLibraries() {
            if library.isNativeLibrary {
                result[library] = library.artifact
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
    
    private class HashableLibrary: Hashable {
        private let library: Library
        
        init(_ library: Library) {
            self.library = library
        }
        
        static func == (lhs: HashableLibrary, rhs: HashableLibrary) -> Bool {
            lhs.library.groupId == rhs.library.groupId
            && lhs.library.artifactId == rhs.library.artifactId
            && lhs.library.classifier == rhs.library.classifier
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(library.groupId)
            hasher.combine(library.artifactId)
            hasher.combine(library.classifier)
        }
    }
}

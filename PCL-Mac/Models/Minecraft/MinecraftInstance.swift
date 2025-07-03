//
//  MinecraftVersion.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/5/20.
//

import Foundation
import SwiftyJSON
import ZIPFoundation

public class MinecraftInstance: Identifiable {
    private static var cache: [URL : MinecraftInstance] = [:]
    
    private static let RequiredJava16: MinecraftVersion = MinecraftVersion(displayName: "21w19a", type: .snapshot)
    private static let RequiredJava17: MinecraftVersion = MinecraftVersion(displayName: "1.18-pre2", type: .snapshot)
    private static let RequiredJava21: MinecraftVersion = MinecraftVersion(displayName: "24w14a", type: .snapshot)
    
    public let runningDirectory: URL
    public let minecraftDirectory: MinecraftDirectory
    public let configPath: URL
    public private(set) var version: MinecraftVersion? = nil
    public var process: Process?
    public let manifest: ClientManifest!
    public var config: MinecraftConfig
    
    public let id: UUID = UUID()
    
    public static func create(runningDirectory: URL, config: MinecraftConfig? = nil, _ caller: String = #file, _ line: Int = #line) -> MinecraftInstance? {
        if let cached = cache[runningDirectory] {
            return cached
        }
        
        if let instance: MinecraftInstance = .init(runningDirectory: runningDirectory, config: config) {
            cache[runningDirectory] = instance
            return instance
        }
        
        return nil
    }
    
    private init?(runningDirectory: URL, config: MinecraftConfig? = nil) {
        self.runningDirectory = runningDirectory
        self.minecraftDirectory = MinecraftDirectory(rootUrl: runningDirectory.parent().parent())
        self.configPath = runningDirectory.appending(path: ".PCL_Mac.json")
        
        if FileManager.default.fileExists(atPath: configPath.path) {
            do {
                let handle = try FileHandle(forReadingFrom: configPath)
                self.config = .init(try .init(data: handle.readToEnd()!))
            } catch {
                err("无法加载配置: \(error.localizedDescription)")
                debug(configPath.path)
                return nil
            }
        } else {
            self.config = config ?? MinecraftConfig(name: runningDirectory.lastPathComponent, mainClass: "")
        }
        
        do {
            let data = try FileHandle(forReadingFrom: runningDirectory.appending(path: runningDirectory.lastPathComponent + ".json")).readToEnd()!
            manifest = switch self.config.clientBrand {
            case .fabric:
                ClientManifest.createFromFabricManifest(.init(try JSON(data: data)), runningDirectory)
            default:
                try ClientManifest.parse(data, instanceUrl: runningDirectory)
            }
        } catch {
            err("无法加载客户端清单: \(error)")
            return nil
        }
        
        detectVersion()
        
        self.version = MinecraftVersion(displayName: self.config.version!)
        if self.config.javaPath == nil {
            self.config.javaPath = MinecraftInstance.findSuitableJava(self.version!)?.executableUrl.path
        }
        self.saveConfig()
    }
    
    public func saveConfig() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            try FileManager.default.createDirectory(
                at: runningDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try encoder.encode(config).write(to: configPath, options: .atomic)
        } catch {
            err("无法保存配置: \(error.localizedDescription)")
        }
    }
    
    public static func findSuitableJava(_ version: MinecraftVersion) -> JavaVirtualMachine? {
        let needsJava16: Bool = version >= RequiredJava16
        let needsJava17: Bool = version >= RequiredJava17
        let needsJava21: Bool = version >= RequiredJava21
        
        var suitableJava: JavaVirtualMachine?
        for jvm in DataManager.shared.javaVirtualMachines.sorted(by: { $0.version < $1.version }) {
            if (jvm.version < 16 && needsJava16)
            || (jvm.version < 17 && needsJava17)
            || (jvm.version < 21 && needsJava21) {
                continue
            }
            
            suitableJava = jvm
            
            if jvm.callMethod == .direct {
                break
            }
        }
        
        if suitableJava == nil {
            warn("未找到可用 Java")
            debug("版本: \(version.displayName)")
            debug("需要 Java 16: \(needsJava16)")
            debug("需要 Java 17: \(needsJava21)")
            debug("需要 Java 21: \(needsJava21)")
        }
        
        return suitableJava
    }
    
    public func launch() async {
        if !config.skipResourcesCheck {
            log("正在进行资源完整性检查")
            await withCheckedContinuation { continuation in
                let task = MinecraftInstaller.createCompleteTask(self, continuation.resume)
                task.start()
            }
        }
        MinecraftLauncher(self)?.launch()
    }
    
    public func detectVersion() {
        guard config.version == nil else {
            return
        }
        
        do {
            let archive = try Archive(url: runningDirectory.appending(path: "\(config.name).jar"), accessMode: .read)
            guard let entry = archive["version.json"] else {
                throw NSError(domain: "MinecraftInstance", code: 2, userInfo: [NSLocalizedDescriptionKey: "version.json 不存在"])
            }
            
            var data = Data()
            _ = try archive.extract(entry, consumer: { (chunk) in
                data.append(chunk)
            })
            
            self.config.version = try JSON(data: data)["id"].stringValue
        } catch {
            err("无法检测版本: \(error.localizedDescription)，正在使用清单版本")
            self.config.version = self.manifest!.id
        }
    }
}

public struct MinecraftConfig: Codable {
    public let name: String
    public var version: String?
    public var mainClass: String
    public var additionalLibraries: Set<String> = []
    public var javaPath: String!
    public var clientBrand: ClientBrand
    public var skipResourcesCheck: Bool = false
    
    public init(_ json: JSON) {
        self.name = json["name"].stringValue
        self.version = json["version"].string
        self.mainClass = json["mainClass"].string ?? "net.minecraft.client.main.Main"
        self.additionalLibraries = .init(json["additionalLibraries"].array?.map { $0.stringValue } ?? [])
        self.javaPath = json["javaPath"].string
        if let clientBrand = json["clientBrand"].string {
            self.clientBrand = .init(rawValue: clientBrand)!
        } else {
            self.clientBrand = .vanilla
        }
        self.skipResourcesCheck = json["skipResourcesCheck"].boolValue
    }
    
    public init(name: String, mainClass: String, javaPath: String? = nil) {
        self.name = name
        self.mainClass = mainClass
        self.javaPath = javaPath
        self.clientBrand = .vanilla
    }
}

public enum ClientBrand: String, Codable {
    case vanilla = "vanilla"
    case fabric = "fabric"
    case forge = "forge"
    case neoforge = "neoforge"
}

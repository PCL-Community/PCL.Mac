//
//  MinecraftVersion.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/20.
//

import Foundation
import SwiftyJSON
import ZIPFoundation
import Cocoa

public class MinecraftInstance: Identifiable, Equatable, Hashable {
    private static var cache: [URL : MinecraftInstance] = [:]
    
    private static let RequiredJava16: MinecraftVersion = MinecraftVersion(displayName: "21w19a", type: .snapshot)
    private static let RequiredJava17: MinecraftVersion = MinecraftVersion(displayName: "1.18-pre2", type: .snapshot)
    private static let RequiredJava21: MinecraftVersion = MinecraftVersion(displayName: "24w14a", type: .snapshot)
    
    public let runningDirectory: URL
    public let minecraftDirectory: MinecraftDirectory
    public let configPath: URL
    public private(set) var version: MinecraftVersion! = nil
    public var process: Process?
    public private(set) var manifest: ClientManifest!
    public var config: MinecraftConfig!
    public var clientBrand: ClientBrand!
    public var isUsingRosetta: Bool = false
    
    public let id: UUID = UUID()
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: MinecraftInstance, rhs: MinecraftInstance) -> Bool {
        lhs.id == rhs.id
    }
    
    public static func create(_ minecraftDirectory: MinecraftDirectory, _ name: String, config: MinecraftConfig? = nil) -> MinecraftInstance? {
        create(minecraftDirectory, minecraftDirectory.versionsURL.appending(path: name), config: config)
    }
    
    public static func create(_ minecraftDirectory: MinecraftDirectory, _ runningDirectory: URL, config: MinecraftConfig? = nil) -> MinecraftInstance? {
        if let cached = cache[runningDirectory] {
            return cached
        }
        
        let instance: MinecraftInstance = .init(minecraftDirectory: minecraftDirectory, runningDirectory: runningDirectory, config: config)
        if instance.setup() {
            cache[runningDirectory] = instance
            return instance
        } else {
            err("实例初始化失败")
            return nil
        }
    }
    
    private init(minecraftDirectory: MinecraftDirectory, runningDirectory: URL, config: MinecraftConfig? = nil) {
        self.runningDirectory = runningDirectory
        self.minecraftDirectory = minecraftDirectory
        self.configPath = runningDirectory.appending(path: ".PCL_Mac.json")
        self.config = config
    }
    
    private func setup() -> Bool {
        // 若配置文件存在，从文件加载配置
        if FileManager.default.fileExists(atPath: configPath.path) {
            do {
                try loadConfig()
            } catch {
                err("无法加载配置: \(error.localizedDescription)")
                debug(configPath.path)
            }
        }
        self.config = config ?? MinecraftConfig(name: runningDirectory.lastPathComponent)
        
        if !loadManifest() { return false }
        if let version = config.minecraftVersion {
            self.version = .init(displayName: version)
        } else {
            detectVersion()
            config.minecraftVersion = version.displayName
        }
        
        // 寻找可用 Java
        if self.config.javaPath == nil {
            self.config.javaPath = MinecraftInstance.findSuitableJava(self.version!)?.executableURL.path
        }
        self.saveConfig()
        return true
    }
    
    public func loadConfig() throws {
        self.config = .init(try .init(data: try FileHandle(forReadingFrom: configPath).readToEnd()!))
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
    
    private static func getClientBrand(_ manifestString: String) -> ClientBrand {
        if manifestString.contains("neoforged") {
            return .neoforge
        } else if manifestString.contains("fabric") {
            return .fabric
        } else if manifestString.contains("forge") {
            return .forge
        } else {
            return .vanilla
        }
    }
    
    public static func getMinJavaVersion(_ version: MinecraftVersion) -> Int {
        if version >= RequiredJava21 {
            return 21
        } else if version >= RequiredJava17 {
            return 17
        } else if version >= RequiredJava16 {
            return 16
        } else {
            return 8
        }
    }
    
    public static func findSuitableJava(_ version: MinecraftVersion) -> JavaVirtualMachine? {
        let minJavaVersion = getMinJavaVersion(version)
        var suitableJava: JavaVirtualMachine?
        for jvm in DataManager.shared.javaVirtualMachines.sorted(by: { $0.version < $1.version }) {
            if jvm.version < minJavaVersion { continue }
            
            suitableJava = jvm
            
            if jvm.callMethod == .direct {
                break
            }
        }
        
        if suitableJava == nil {
            warn("未找到可用 Java")
            debug("版本: \(version.displayName)")
            debug("最低 Java 版本: \(minJavaVersion)")
        }
        
        return suitableJava
    }
    
    public func launch(_ launchOptions: LaunchOptions) async {
        if let account = launchOptions.account {
            launchOptions.playerName = account.name
            launchOptions.uuid = account.uuid
            log("正在登录")
            launchOptions.accessToken = await account.getAccessToken()
        }
        launchOptions.javaPath = URL(fileURLWithPath: config.javaPath)
        
        let _ = loadManifest()
        if Architecture.getArchOfFile(launchOptions.javaPath) == .arm64 && Architecture.system == .arm64 {
            ArtifactVersionMapper.map(manifest)
            isUsingRosetta = false
        } else {
            ArtifactVersionMapper.map(manifest, arch: .x64)
            isUsingRosetta = true
            warn("正在使用 Rosetta 运行 Minecraft")
        }
        
        if !config.skipResourcesCheck && !launchOptions.skipResourceCheck {
            log("正在进行资源完整性检查")
            await withCheckedContinuation { continuation in
                let task = MinecraftInstaller.createCompleteTask(self, continuation.resume)
                task.start()
            }
            log("资源完整性检查完成")
        }
        
        let launcher = MinecraftLauncher(self)!
        launcher.launch(launchOptions) { exitCode in
            if exitCode != 0 {
                log("检测到非 0 退出代码")
                hint("检测到 Minecraft 出现错误，错误分析已开始……")
                ContentView.setPopup(.init("Minecraft 出现错误", "很抱歉，PCL.Mac 暂时没有分析功能。\n如果要寻求帮助，请把错误报告文件发给对方，而不是发送这个窗口的照片或者截图。\n不要截图！不要截图！！不要截图！！！", [
                    .Ok,
                    .init(text: "导出错误报告", onClick: {
                        let savePanel = NSSavePanel()
                        savePanel.title = "选择导出位置"
                        savePanel.prompt = "导出"
                        savePanel.allowedContentTypes = [.zip]
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-M-d_HH.mm.ss"
                        savePanel.nameFieldStringValue = "错误报告-\(formatter.string(from: .init()))"
                        savePanel.beginSheetModal(for: NSApplication.shared.windows.first!) { [unowned self] result in
                            if result == .OK {
                                if let url = savePanel.url {
                                    MinecraftCrashHandler.exportErrorReport(self, launcher, to: url)
                                }
                            }
                        }
                        PopupButton.Close.onClick()
                    })
                ]))
            }
        }
    }
    
    private func loadManifest() -> Bool {
        do {
            let data = try FileHandle(forReadingFrom: runningDirectory.appending(path: runningDirectory.lastPathComponent + ".json")).readToEnd()!
            self.clientBrand = MinecraftInstance.getClientBrand(String(data: data, encoding: .utf8) ?? "")
            let json = try JSON(data: data)
            let manifest: ClientManifest?
            switch self.clientBrand {
            case .fabric:
                if json["loader"].exists() {
                    manifest = ClientManifest.createFromFabricManifest(.init(json), runningDirectory)
                } else {
                    manifest = try ClientManifest.parse(data, instanceURL: runningDirectory)
                }
            default:
                manifest = try ClientManifest.parse(data, instanceURL: runningDirectory)
            }
            guard let manifest = manifest else { return false }
            self.manifest = manifest
//            ArtifactVersionMapper.map(self.manifest)
        } catch {
            err("无法加载客户端清单: \(error.localizedDescription)")
            return false
        }
        
        return true
    }
    
    private func detectVersion() {
        guard version == nil else {
            return
        }
        do {
            let archive = try Archive(url: runningDirectory.appending(path: "\(config.name).jar"), accessMode: .read)
            guard let entry = archive["version.json"] else {
                throw NSError(domain: "MinecraftInstance", code: -1, userInfo: [NSLocalizedDescriptionKey: "version.json 不存在"])
            }
            
            var data = Data()
            _ = try archive.extract(entry, consumer: { (chunk) in
                data.append(chunk)
            })
            
            let version = MinecraftVersion(displayName: try JSON(data: data)["id"].stringValue)
            self.version = version
        } catch {
            err("无法检测版本: \(error.localizedDescription)，正在使用清单版本")
            self.version = .init(displayName: manifest.id)
        }
    }
    
    public func getIconName() -> String {
        if self.clientBrand == .vanilla {
            return self.version.getIconName()
        }
        return "\(self.clientBrand.rawValue.capitalized)Icon"
    }
}

public struct MinecraftConfig: Codable {
    public let name: String
    public var additionalLibraries: Set<String> = []
    public var javaPath: String!
    public var skipResourcesCheck: Bool = false
    public var maxMemory: Int32 = 4096
    public var qualityOfService: QualityOfService = .default
    public var minecraftVersion: String?
    
    public init(_ json: JSON) {
        self.name = json["name"].stringValue
        self.additionalLibraries = .init(json["additionalLibraries"].array?.map { $0.stringValue } ?? [])
        self.javaPath = json["javaPath"].string
        self.skipResourcesCheck = json["skipResourcesCheck"].boolValue
        self.maxMemory = json["maxMemory"].int32 ?? 4096
        self.qualityOfService = .init(rawValue: json["qualityOfService"].intValue) ?? .default
        self.minecraftVersion = json["minecraftVersion"].string
        if qualityOfService.rawValue == 0 {
            qualityOfService = .default
        }
    }
    
    public init(name: String, javaPath: String? = nil) {
        self.name = name
        self.javaPath = javaPath
    }
}

public enum ClientBrand: String, Codable, Hashable {
    case vanilla = "vanilla"
    case fabric = "fabric"
    case quilt = "quilt"
    case forge = "forge"
    case neoforge = "neoforge"
    
    public func getName() -> String {
        if self == .neoforge {
            return "NeoForge"
        } else {
            return self.rawValue.capitalized
        }
    }
    
    public var index: Int {
        switch self {
        case .vanilla: 0
        case .fabric: 1
        case .quilt: 2
        case .forge: 3
        case .neoforge: 4
        }
    }
}

extension QualityOfService: Codable { }

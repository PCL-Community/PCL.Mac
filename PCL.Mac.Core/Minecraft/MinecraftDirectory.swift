//
//  MinecraftDirectory.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/30.
//

import Foundation

public class MinecraftDirectory: Codable, Identifiable, Hashable {
    public static let `default`: MinecraftDirectory = .init(rootURL: .applicationSupportDirectory.appending(path: "minecraft"), name: "默认文件夹")
    
    public var id: UUID
    public let rootURL: URL
    public var name: String
    public var instances: [InstanceInfo] = []
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rootURL)
    }
    
    public var versionsURL: URL {
        rootURL.appendingPathComponent("versions")
    }
    
    public var assetsURL: URL {
        rootURL.appendingPathComponent("assets")
    }
    
    public var librariesURL: URL {
        rootURL.appendingPathComponent("libraries")
    }
    
    public init(rootURL: URL, name: String) {
        self.id = .init()
        self.rootURL = rootURL
        self.name = name
    }
    
    enum CodingKeys: CodingKey {
        case id
        case rootURL
        case name
    }
    
    public static func == (lhs: MinecraftDirectory, rhs: MinecraftDirectory) -> Bool {
        lhs.rootURL == rhs.rootURL
    }
    
    public func loadInnerInstances(callback: (([InstanceInfo]) -> Void)? = nil) {
        instances.removeAll()
        Task {
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: versionsURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
                let instanceDirectories = contents.filter { url in
                    (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
                }
                for instanceDirectory in instanceDirectories {
                    if let instance = MinecraftInstance.create(self, instanceDirectory) {
                        let info = InstanceInfo(
                            minecraftDirectory: self,
                            icon: instance.getIconName(),
                            name: instance.name,
                            version: instance.version,
                            runningDirectory: instanceDirectory,
                            brand: instance.clientBrand
                        )
                        DispatchQueue.main.async {
                            self.instances.append(info)
                        }
                    }
                }
                DispatchQueue.main.async {
                    callback?(self.instances)
                    DataManager.shared.objectWillChange.send()
                }
            } catch {
                err("读取版本目录失败: \(error.localizedDescription)")
            }
        }
    }
}

public struct InstanceInfo: Identifiable, Hashable {
    public let id: UUID = .init()
    public let minecraftDirectory: MinecraftDirectory
    public let icon: String
    public let name: String
    public let version: MinecraftVersion
    public let runningDirectory: URL
    public let brand: ClientBrand
}

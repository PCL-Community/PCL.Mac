//
//  MinecraftDirectory.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/30.
//

import Foundation

public struct MinecraftDirectory {
    public let rootUrl: URL
    
    public var versionsUrl: URL {
        rootUrl.appendingPathComponent("versions")
    }
    
    public var assetsUrl: URL {
        rootUrl.appendingPathComponent("assets")
    }
    
    public var librariesUrl: URL {
        rootUrl.appendingPathComponent("libraries")
    }
    
    public init(rootUrl: URL) {
        self.rootUrl = rootUrl
    }
    
    public func getInnerInstances() -> [MinecraftInstance] {
        var instances: [MinecraftInstance] = []
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: versionsUrl, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            let folderUrls = contents.filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }
            for folderUrl in folderUrls {
                if let version = MinecraftInstance.create(runningDirectory: folderUrl) {
                    instances.append(version)
                }
            }
        } catch {
            err("读取版本目录失败: \(error)")
        }
        return instances
    }
}

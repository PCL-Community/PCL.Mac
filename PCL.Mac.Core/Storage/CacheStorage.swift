//
//  CacheStorage.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/10.
//

import Foundation
import SwiftyJSON

public class CacheStorage {
    public static let `default`: CacheStorage = .init(rootUrl: .applicationSupportDirectory.appending(path: "minecraft").appending(path: "cache"))
    
    private let rootUrl: URL
    private var libraries: [Library]
    
    public init(rootUrl: URL) {
        self.rootUrl = rootUrl
        try? FileManager.default.createDirectory(at: rootUrl.parent(), withIntermediateDirectories: true)
        do {
            let data = try FileHandle(forReadingFrom: rootUrl.appending(path: "index.json")).readToEnd()!
            let json = try JSON(data: data)
            self.libraries = json["libraries"].arrayValue.map(Library.init)
        } catch {
            err("无法读取 index.json: \(error.localizedDescription)")
            self.libraries = []
        }
    }
    
    public func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            try encoder.encode(["libraries" : libraries]).write(to: rootUrl.appending(path: "index.json"), options: .atomic)
        } catch {
            err("无法保存 libraries: \(error.localizedDescription)")
        }
    }
    
    public func getLibraryPath(_ hash: String) -> URL {
        rootUrl
            .appending(path: "SHA-1")
            .appending(path: String(hash.prefix(2)))
            .appending(path: hash)
    }
    
    public func copy(name: String, to dest: URL) -> Bool {
        if FileManager.default.fileExists(atPath: dest.path) {
            return true
        }
        if let library = libraries.first(where: { $0.name == name }) {
            let path = getLibraryPath(library.hash)
            
            guard FileManager.default.fileExists(atPath: path.path) else {
                err("\(library.name) 对应的文件 (\(path.path)) 不存在！")
                libraries.removeAll(where: { $0.hash == library.hash })
                save()
                return false
            }
            
            do {
                try? FileManager.default.createDirectory(at: dest.parent(), withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: path, to: dest)
                debug("成功拷贝文件: \(name)")
                return true
            } catch {
                err("无法拷贝文件: \(error.localizedDescription)")
            }
        }
        return false
    }
    
    public func add(name: String, path: URL) {
        if libraries.contains(where: { $0.name == name }) {
            return
        }
        
        let hash: String
        do {
            hash = try Util.sha1OfFile(url: path)
        } catch {
            err("无法获取 SHA-1: \(error.localizedDescription)")
            return
        }
        let dest = getLibraryPath(hash)
        if FileManager.default.fileExists(atPath: dest.path) { return }
        
        do {
            try FileManager.default.copyItem(at: path, to: dest)
        } catch {
            err("无法复制文件: \(error.localizedDescription)")
            return
        }
        
        libraries.append(.init(name: name, hash: hash, type: "jar"))
    }
    
    private struct Library: Codable {
        public let name: String
        public let hash: String
        public let type: String
        
        init(name: String, hash: String, type: String) {
            self.name = name
            self.hash = hash
            self.type = type
        }
        
        init(_ json: JSON) {
            self.name = json["name"].stringValue
            self.hash = json["hash"].stringValue
            self.type = json["type"].stringValue
        }
    }
}

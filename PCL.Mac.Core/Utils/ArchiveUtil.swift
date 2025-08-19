//
//  ArchiveUtil.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/30.
//

import Foundation
import ZIPFoundation

public class ArchiveUtil {
    public static func hasEntry(url: URL, name: String) -> Bool {
        do {
            let archive = try Archive(url: url, accessMode: .read)
            return hasEntry(archive: archive, name: name)
        } catch {
            err("无法读取归档: \(error.localizedDescription)")
        }
        return false
    }
    
    public static func hasEntry(archive: Archive, name: String) -> Bool {
        return archive[name] != nil
    }
    
    public static func getEntryOrThrow(url: URL, name: String) throws -> Data {
        return try getEntryOrThrow(archive: Archive(url: url, accessMode: .read), name: name)
    }
    
    public static func getEntryOrThrow(archive: Archive, name: String) throws -> Data {
        if let manifest = archive[name] {
            var data = Data()
            _ = try archive.extract(manifest, consumer: { (chunk) in
                data.append(chunk)
            })
            return data
        }
        throw MyLocalizedError(reason: "项 \(name) 不存在")
    }
    
    public static func getEntry(url: URL, name: String) -> Data? {
        try? getEntryOrThrow(url: url, name: name)
    }
    
    private init() {}
}

//
//  ZipUtil.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/30.
//

import Foundation
import ZIPFoundation

public class ZipUtil {
    public static func getEntryOrThrow(archive: Archive, name: String) throws -> Data {
        if let manifest = archive[name] {
            var data = Data()
            _ = try archive.extract(manifest, consumer: { (chunk) in
                data.append(chunk)
            })
            return data
        }
        throw NSError(domain: "ZipUtil", code: -1, userInfo: [NSLocalizedDescriptionKey: "项 \(name) 不存在！"])
    }
    
    public static func getEntry(archive: Archive, name: String) -> Data? {
        try? getEntryOrThrow(archive: archive, name: name)
    }
    
    private init() {}
}

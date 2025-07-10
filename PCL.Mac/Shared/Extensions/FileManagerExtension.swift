//
//  FileManagerExtension.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/19.
//

import Foundation

extension FileManager {
    static let logURL = SharedConstants.shared.applicationLogUrl
    
    static func writeLog(_ content: String) throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: logURL.path) {
            try fileManager.createDirectory(
                at: logURL.parent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            fileManager.createFile(atPath: logURL.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: logURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(content.utf8))
    }
}

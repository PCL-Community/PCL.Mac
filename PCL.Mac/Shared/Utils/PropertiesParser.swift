//
//  PropertiesParser.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/18.
//

import Foundation

public struct PropertiesParser {
    public static func parse(fileUrl: URL) -> [String: String] {
        guard let content = try? String(contentsOf: fileUrl, encoding: .utf8) else {
            print("Error: 文件读取失败")
            return [:]
        }
        
        var result = [String: String]()
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty,
                  !trimmedLine.starts(with: "#"),
                  !trimmedLine.starts(with: "!") else {
                continue
            }
            if let (key, value) = parsePropertyLine(trimmedLine) {
                result[key] = value
            }
        }
        
        return result
    }
    
    private static func parsePropertyLine(_ line: String) -> (key: String, value: String)? {
        let parts = line.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }
        
        let rawKey = String(parts[0]).trimmingCharacters(in: .whitespaces)
        var rawValue = String(parts[1])
        
        if let commentIndex = rawValue.firstIndex(where: { $0 == "#" || $0 == "!" }) {
            rawValue = String(rawValue[..<commentIndex])
        }
        
        let trimmedValue = rawValue
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        
        return (rawKey, trimmedValue)
    }
}

//
//  Util.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/6/18.
//

import Foundation
import ZIPFoundation

public class Util {
    public static func getMainClass(_ jarUrl: URL) -> String? {
        do {
            let archive = try Archive(url: jarUrl, accessMode: .read)
            if let manifest = archive["META-INF/MANIFEST.MF"] {
                var data = Data()
                _ = try archive.extract(manifest, consumer: { (chunk) in
                    data.append(chunk)
                })
                
                let manifest = String(data: data, encoding: .utf8)!

                if let match = manifest.firstMatch(of: /(?m)^Main-Class:\s*([^\r\n]+)/) {
                    return String(match.1)
                }
            }
        } catch {
            err("无法获取主类: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    public static func formatJSON(_ jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            let prettyData = try JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.prettyPrinted]
            )
            return String(data: prettyData, encoding: .utf8)
        } catch {
            err("JSON格式化失败: \(error)")
            return nil
        }
    }
    
    public static func parse(mavenCoordinate: String) -> MavenCoordinate {
        let pattern = #"^([^:]+):([^:]+):([^:@]+)(?::([^@]+))?(?:@(.+))?$"#
        let r = mavenCoordinate.range(of: pattern, options: .regularExpression)!
        let match = String(mavenCoordinate[r])
        let regex = try! NSRegularExpression(pattern: pattern)
        let nsrange = NSRange(match.startIndex..<match.endIndex, in: match)
        let result = regex.firstMatch(in: match, options: [], range: nsrange)!
        func group(_ i: Int) -> String? {
            guard let range = Range(result.range(at: i), in: match) else { return nil }
            return String(match[range])
        }
        return MavenCoordinate(
            group(1)!,
            group(2)!,
            group(3)!,
            classifier: group(4),
            packaging: group(5)
        )
    }
    
    public static func toPath(mavenCoordinate: String) -> String {
        let coord = parse(mavenCoordinate: mavenCoordinate)
        return "\(coord.groupId.replacingOccurrences(of: ".", with: "/"))/\(coord.artifactId)/\(coord.version)/\(coord.artifactId)-\(coord.version)"
        + (coord.classifier != nil ? "-" + coord.classifier! : "")
        + "." + (coord.packaging != nil ? coord.packaging! : "jar")
    }
    
    public static func replaceTemplateStrings(_ strings: [String], with dict: [String: String]) -> [String] {
        return strings.map { original in
            var result = original
            for (key, value) in dict {
                result = result
                    .replacingOccurrences(of: "${\(key)}", with: value)
                    .replacingOccurrences(of: "{\(key)}", with: value)
            }
            return result
        }
    }
    
    public static func clearTemp() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: SharedConstants.shared.applicationTemperatureUrl,
                includingPropertiesForKeys: nil,
                options: []
            )
            for itemURL in contents {
                try FileManager.default.removeItem(at: itemURL)
            }
        } catch {
            err("在清理时发生错误: \(error.localizedDescription)")
        }
    }
}

public struct MavenCoordinate {
    public let groupId: String
    public let artifactId: String
    public let version: String
    public let classifier: String?
    public let packaging: String?
    
    init(_ groupId: String, _ artifactId: String, _ version: String, classifier: String? = nil, packaging: String? = nil) {
        self.groupId = groupId
        self.artifactId = artifactId
        self.version = version
        self.classifier = classifier
        self.packaging = packaging
    }
}

//
//  JavaDownloader.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/1.
//

import Foundation
import SwiftyJSON

/// Azul Zulu Java 下载 / 搜索器
public class JavaDownloader {
    public static func search(
        version: String? = nil,
        arch: Architectury = .system,
        type: JavaPackage.JavaType? = nil,
        page: Int = 1
    ) async throws -> [JavaPackage] {
        var packages: [JavaPackage] = []
        var params: [String : String] = [
            "os": "macos",
            "archive_type": "zip",
            "arch": String(describing: arch)
        ]
        
        if let version = version { params["java_version"] = version }
        if let type = type { params["java_package_type"] = type.rawValue }
        
        let json = try await Requests.get(
            "https://api.azul.com/metadata/v1/zulu/packages/",
            body: params,
            encodeMethod: .urlEncoded
        ).getJSONOrThrow()
        
        for package in json.arrayValue {
            if let match = package["name"].stringValue.wholeMatch(of: /zulu.*-ca-fx-(jdk|jre)[0-9.]+-macosx_(x64|aarch64)\.zip/) {
                let type = String(match.1)
                let arch = String(match.2)
                
                packages.append(JavaPackage(
                    type: .init(rawValue: type) ?? .jre,
                    arch: .fromString(arch),
                    version: package["java_version"].arrayValue.map { $0.intValue },
                    downloadURL: package["download_url"].url!
                ))
            }
        }
        
        return packages
    }
}

public struct JavaPackage {
    public let type: JavaType
    public let arch: Architectury
    public let version: [Int]
    public var versionString: String { version.map { String($0) }.joined(separator: ".") }
    public let downloadURL: URL
    
    public enum JavaType: String { case jre, jdk }
}

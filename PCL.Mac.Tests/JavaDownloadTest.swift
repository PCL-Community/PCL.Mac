//
//  JavaDownloadTest.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/1.
//

import Foundation
import Testing
import PCL_Mac
import SwiftUI
import Cocoa
import UserNotifications
import SwiftyJSON

struct JavaDownloadTest {
    @Test func testFetchVersions() async throws {
        let json: JSON = try await Requests.get(
            "https://api.azul.com/metadata/v1/zulu/packages/",
            body: [
                "os": "macos"
            ],
            encodeMethod: .urlEncoded
        ).getJSONOrThrow()
        
        for pkg in json.arrayValue {
            print(pkg["java_version"].arrayValue)
        }
    }
    
    @Test func testDownloadJava() async throws {
        let temp = TemperatureDirectory(name: "JavaDownload")
        try? FileManager.default.createDirectory(at: temp.root, withIntermediateDirectories: true)
        
        let json: JSON = try await Requests.get(
            "https://api.azul.com/metadata/v1/zulu/packages/ec2300fd-f213-4673-a241-480ae7c28bc4"
        ).getJSONOrThrow()
        print(json["name"].stringValue)
        print("架构: \(json["arch"].stringValue)")
        print("版本: \(json["java_version"].arrayValue.map { String($0.intValue) }.joined(separator: "."))")
        
        let name = json["name"].stringValue.dropLast(4)
        let destination = temp.root.appending(path: json["name"].stringValue)
        let downloader = ChunkedDownloader(
            url: json["download_url"].url!,
            destination: destination,
            chunkCount: 8
        )
        await downloader.start()
        print("下载完成")
        
        
        Util.unzip(archiveUrl: destination, destination: temp.root, replace: false)
        
        let javaDirectoryPath = temp.root.appending(path: name).appending(path: "bin").resolvingSymlinksInPath().parent().parent().parent()
        let saveURL = URL(fileURLWithUserPath: "~/Library/Java/JavaVirtualMachines").appending(path: javaDirectoryPath.lastPathComponent)
        
        try? FileManager.default.createDirectory(
            at: saveURL.parent(),
            withIntermediateDirectories: true
        )
        try? FileManager.default.copyItem(at: javaDirectoryPath, to: saveURL)
        
        print("安装完成")
    }
}

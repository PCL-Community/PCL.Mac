//
//  JavaDownloadTest.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/1.
//

import Foundation
import Testing
import PCL_Mac
import SwiftyJSON

struct JavaDownloadTest {
    @Test func testFetchVersions() async throws {
        let packages = try await JavaDownloader.search(version: "1.8")
        for package in packages.prefix(10) {
            print(package.versionString)
        }
    }
    
    @Test func testDownloadJava() async throws {
        let package = try await JavaDownloader.search().first!
        let task = JavaInstallTask(package: package)
        await withCheckedContinuation { continuation in
            task.onComplete(continuation.resume)
            task.start()
        }
    }
    
    @Test func testMatchFileName() {
        if let match = "zulu24.32.13-ca-crac-jdk24.0.2-macosx_aarch64.zip".wholeMatch(of: /zulu.*-ca-fx-(jdk|jre)([0-9.]+)-macosx_(x64|aarch64)\.zip/) {
            let type = match.1
            let version = match.2
            let arch = match.3
            print("type: \(type), version: \(version), arch: \(arch)")
        } else {
            assertionFailure()
        }
    }
}

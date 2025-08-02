//
//  Aria2Tests.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/2/25.
//

import Foundation
import Testing
import PCL_Mac

struct Aria2Tests {
    @Test func testDownloadAria2() async throws {
        try await Aria2Manager.shared.downloadAria2()
    }
    
    @Test func testDownload() async throws {
        print(FileManager.default.fileExists(atPath: Aria2Manager.shared.executableURL.path))
        try await Aria2Manager.shared.download(url: URL(string: "https://cdn.azul.com/zulu/bin/zulu24.32.13-ca-fx-jdk24.0.2-macosx_aarch64.zip")!, destination: URL(fileURLWithPath: "/tmp/zulu.zip"))
    }
}

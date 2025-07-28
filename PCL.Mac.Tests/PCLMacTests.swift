//
//  PCL_MacTests.swift
//  PCL.MacTests
//
//  Created by YiZhiMCQiu on 2025/5/18.
//

import Foundation
import Testing
import PCL_Mac
import SwiftUI
import Cocoa
import UserNotifications
import SwiftyJSON

struct PCL_MacTests {
    @Test func testChunkedDownload() async {
        var before = Date()
        let downloader = ChunkedDownloader(
            url: URL(string: "https://resources.download.minecraft.net/c7/c7076fbff7278950d7d571d2e36f66ce994e2988")!,
            destination: URL(fileURLWithPath: "/tmp/test"),
            chunkCount: 32
        )
        await downloader.start()
        print(Date().distance(to: before))
        
        before = Date()
        let response = await Requests.get("https://resources.download.minecraft.net/c7/c7076fbff7278950d7d571d2e36f66ce994e2988")
        print(response.data!.count)
        print(Date().distance(to: before))
    }
    
    @Test func testDownload() async {
        await withCheckedContinuation { continuation in
            let task = MinecraftInstaller.createTask(.init(displayName: "1.21.8"), "1.21.8", .default, continuation.resume)
            task.start()
        }
    }
}

//
//  DownloaderTests.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/24.
//

import Foundation
import PCL_Mac
import Testing

struct DownloaderTests {
    @Test func testSingleFileDownload() async throws {
        try await SingleFileDownloader.download(url: "https://bmclapi2.bangbang93.com/version/1.21/client".url, destination: URL(fileURLWithUserPath: "~/test.file"), replaceMethod: .replace) { progress in
            print(progress)
        }
    }
    
    @Test func testMultiFileDownload() async throws {
        let versions = ["1.21", "1.19", "1.14.2"]
        
        let downloader = MultiFileDownloader(
            items: versions.map {
                DownloadItem("https://bmclapi2.bangbang93.com/version/\($0)/client".url, URL(fileURLWithPath: "/tmp/\($0).jar"))
            },
            concurrentLimit: 4,
            replaceMethod: .replace
        ) { progress, finished in
            print(String(format: "%.2f%% %d", progress, finished))
        }
        
        try await downloader.start()
    }
}

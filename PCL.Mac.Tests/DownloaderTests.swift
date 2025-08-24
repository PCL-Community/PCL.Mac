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
        try await SingleFileDownloader.download(url: "https://libraries.minecraft.net/oshi-project/oshi-core/1.1/oshi-core-1.1.jar".url, destination: URL(fileURLWithUserPath: "~/test.file")) { progress in
            print(progress)
        }
    }
    
    @Test func testMultiFileDownload() async throws {
        let files = [
            "97/977e87e9f30b5b4b35d7a8fc7355a1d891f7c2c8",
            "b6/b62ca8ec10d07e6bf5ac8dae0c8c1d2e6a1e3356",
            "5f/5ff04807c356f1beed0b86ccf659b44b9983e3fa",
            "80/8030dd9dc315c0381d52c4782ea36c6baf6e8135",
            "9e/9e62c9342ae2066c8222150c22911f1857affa55",
            "3d/3db046e681a9888135e84e20a3e009575be65c62",
            "e7/e7a439e6fe0d1ec8712e002a00b3f655d2ef9660",
            "94/94e5b3f27e93bd060066e3e8aa45aac7eeababf6",
            "error/test"
        ]
        
        try await MultiFileDownloader.download(
            items: files.map { DownloadItem("https://resources.download.minecraft.net/\($0)".url, URL(fileURLWithPath: "/tmp/\($0)")) },
            concurrentLimit: 16
        )
    }
}

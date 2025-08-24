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
}

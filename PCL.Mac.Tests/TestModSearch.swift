//
//  TestModSearch.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/27.
//

import PCL_Mac
import Testing

struct TestModSearch {
    @Test func testSearch() async throws {
        let result = try await ProjectSearcher.shared.search(type: "modpack", query: "")
        for summary in result {
            print("\(summary.loaders)")
        }
    }
    
    @Test func testGetVersions() async throws {
        let sodium = try await ModSearcher.shared.get("iris")
        for version in sodium.versions! {
            let version = try await ModSearcher.shared.getVersion(version)
            print(version.name)
        }
    }
}

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
        let result = try await ModrinthProjectSearcher.shared.search(type: .mod, query: "")
        for summary in result {
            print("\(summary.loaders)")
        }
    }
}

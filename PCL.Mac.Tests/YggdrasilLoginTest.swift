//
//  YggdrasilLoginTest.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/8/25.
//

import PCL_Mac
import Foundation
import Testing

struct YggdrasilLoginTest {
    @Test func testLogin() async throws {
        let account = try await YggdrasilAccount(
            authenticationServer: URL(string: "https://littleskin.cn/api/yggdrasil")!,
            accountIdentifier: "YiZhiMCQiu",
            password: "自己猜去"
        )
        print(account.name)
        print(account.uuid.uuidString)
    }
}

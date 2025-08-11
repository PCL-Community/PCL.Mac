//
//  YggdrasilClientTest.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/8/25.
//

import PCL_Mac
import Foundation
import Testing

struct YggdrasilClientTest {
    @Test func testLogin() async throws {
        let client = YggdrasilClient(URL(string: "https://littleskin.cn/api/yggdrasil")!)
        let response = try await client.authenticate(identifier: "YiZhiMCQiu", password: "")
        print(response.accessToken)
        print(response.clientToken)
        print(response.profileUUID)
        print(response.profileName)
    }
    
    @Test func testGetProfile() async throws {
        let client = YggdrasilClient(URL(string: "https://littleskin.cn/api/yggdrasil")!)
        let profile = try await client.getProfile(id: "b46b6b53c9f443209f882daff64e3628")
        print(profile.name)
        print(profile.properties)
    }
}

//
//  SkinCacheStorage.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/11.
//

import Foundation

class SkinCacheStorage {
    public static let shared: SkinCacheStorage = .init()
    
    @CodableAppStorage("skinCache") var skinCache: [UUID : Data] = [:]
    
    @discardableResult
    public func loadSkin(account: AnyAccount) async throws -> Data {
        let skinData = try await account.getSkinData()
        skinCache[account.uuid] = skinData
        return skinData
    }
    
    private init() {}
}

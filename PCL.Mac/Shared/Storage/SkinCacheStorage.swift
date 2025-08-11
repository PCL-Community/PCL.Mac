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
    
    private init() {}
}

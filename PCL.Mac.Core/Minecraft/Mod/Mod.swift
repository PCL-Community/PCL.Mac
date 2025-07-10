//
//  Mod.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/19.
//

import Foundation

public class Mod {
    /// 模组 ID
    public let id: String
    
    /// 模组支持的加载器
    public let brand: ClientBrand
    
    /// 模组的 JAR 文件名
    public let fileName: String
    
    init(id: String, brand: ClientBrand, fileName: String) {
        self.id = id
        self.brand = brand
        self.fileName = fileName
    }
}

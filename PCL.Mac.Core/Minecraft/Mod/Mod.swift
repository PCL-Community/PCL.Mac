//
//  Mod.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/19.
//

import Foundation
import SwiftyJSON

public class Mod: Identifiable, ObservableObject {
    /// 模组 ID
    public let id: String
    
    /// 模组名
    public let name: String
    
    /// 模组描述
    public let description: String
    
    /// 模组支持的加载器
    public let brand: ClientBrand
    
    /// 模组版本
    public let version: String
    
    /// 模组对应的 Modrinth Project，可能为 nil，在加载 Mod 列表时设置
    @Published public var summary: ProjectSummary?
    
    init(id: String, name: String, description: String, brand: ClientBrand, version: String) {
        self.id = id
        self.name = name
        self.description = description
        self.brand = brand
        self.version = version
    }
    
    public static func fromFabricJSON(_ json: JSON) -> Mod {
        return .init(
            id: json["id"].stringValue,
            name: json["name"].stringValue,
            description: json["description"].stringValue,
            brand: .fabric,
            version: json["version"].stringValue
        )
    }
}

//
//  Mod.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/19.
//

import Foundation
import SwiftyJSON
import TOMLKit
import ZIPFoundation

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
    
    public static func loadMod(url: URL) -> Mod? {
        do {
            let archive = try Archive(url: url, accessMode: .read)
            if ArchiveUtil.hasEntry(archive: archive, name: "fabric.mod.json") {
                return fromJSON(json: try JSON(data: ArchiveUtil.getEntryOrThrow(archive: archive, name: "fabric.mod.json")))
            } else if ArchiveUtil.hasEntry(archive: archive, name: "META-INF/mods.toml") {
                return try fromTOML(string: String(data: ArchiveUtil.getEntryOrThrow(archive: archive, name: "META-INF/mods.toml"), encoding: .utf8).unwrap(), brand: .forge)
            } else if ArchiveUtil.hasEntry(archive: archive, name: "META-INF/neoforge.mods.toml") {
                return try fromTOML(string: String(data: ArchiveUtil.getEntryOrThrow(archive: archive, name: "META-INF/neoforge.mods.toml"), encoding: .utf8).unwrap(), brand: .neoforge)
            }
        } catch {
            err("无法加载 Mod \(url.lastPathComponent): \(error.localizedDescription)")
        }
        return nil
    }
    
    private static func fromJSON(json: JSON) -> Mod {
        return .init(
            id: json["id"].stringValue,
            name: json["name"].stringValue,
            description: json["description"].stringValue,
            brand: .fabric,
            version: json["version"].stringValue
        )
    }
    
    private static func fromTOML(string: String, brand: ClientBrand) throws -> Mod {
        let table = try TOMLTable(string: string)
        let modTable = try table["mods"].unwrap().array.unwrap()[0].table.unwrap()
        
        return .init(
            id: modTable["modId"]?.string ?? "",
            name: modTable["displayName"]?.string ?? "",
            description: modTable["description"]?.string ?? "",
            brand: brand,
            version: modTable["version"]?.string ?? ""
        )
    }
}

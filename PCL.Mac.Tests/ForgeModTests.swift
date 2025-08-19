//
//  ForgeModTests.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/19.
//

import Foundation
import Testing
import ZIPFoundation
import PCL_Mac
import TOMLKit

struct ForgeModTests {
    @Test func testModAnalysis() throws {
        let archive = try Archive(url: URL(fileURLWithUserPath: "~/minecraft/sodium-neoforge-0.6.13+mc1.21.5.jar"), accessMode: .read)
        let tomlData =
            (try? ArchiveUtil.getEntryOrThrow(archive: archive, name: "META-INF/mods.toml")) ??
            (try? ArchiveUtil.getEntryOrThrow(archive: archive, name: "META-INF/neoforge.mods.toml"))
        
        let toml = try TOMLTable(string: String(data: tomlData.unwrap(), encoding: .utf8)!)
        let modTable = try toml["mods"].unwrap("无法解析 mods.toml")
            .array.unwrap("无法解析 mods.toml")[0]
            .table.unwrap("无法解析 mods.toml")
        
        let modId = modTable["modId"]?.string ?? ""
        let displayName = modTable["displayName"]?.string ?? ""
        let description = modTable["description"]?.string ?? ""
        print("modId: \(modId)")
        print("displayName: \(displayName)")
        print("description: \(description)")
    }
}

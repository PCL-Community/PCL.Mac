//
//  NeoforgeInstaller.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/17.
//

import Foundation
import ZIPFoundation
import SwiftyJSON

public class NeoforgeInstaller: ForgeInstaller {
    override func getInstallerDownloadURL(_ minecraftVersion: MinecraftVersion, _ version: String) -> URL {
        return URL(string: "https://bmclapi2.bangbang93.com/neoforge/version/\(version)/download/installer.jar")!
    }
    
    override func getGroupId() -> String { "net.neoforged" }
}

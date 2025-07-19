//
//  FabricManifest.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/17.
//

import Foundation
import SwiftyJSON

public class FabricManifest: Identifiable {
    public var id: UUID = .init()
    public var libraries: [ClientManifest.Library] = []
    public let loaderVersion: String
    public let stable: Bool
    public let mainClass: String
    public let jsonString: String // 不应该写在这里，但写安装里太麻烦了 awa
    public let minecraftVersion: String
    
    public init?(_ json: JSON) {
        jsonString = json.rawString()!
        
        loaderVersion = json["loader"]["version"].stringValue
        stable = json["loader"]["stable"].boolValue
        
        guard let loader: ClientManifest.Library = .init(json: .init(
            [
                "name": json["loader"]["maven"].stringValue,
                "url": "https://maven.fabricmc.net/"
            ]
        )) else { return nil }
        
        guard let intermediary: ClientManifest.Library = .init(json: .init(
            [
                "name": json["intermediary"]["maven"].stringValue,
                "url": "https://maven.fabricmc.net/"
            ]
        )) else { return nil }
        
        minecraftVersion = json["intermediary"]["version"].stringValue
        
        libraries.append(loader)
        libraries.append(intermediary)
        
        for key in ["client", "common"] {
            for library in json["launcherMeta"]["libraries"][key].arrayValue {
                guard let library = ClientManifest.Library(json: library) else { return nil }
                libraries.append(library)
            }
        }
        
        mainClass = json["launcherMeta"]["mainClass"]["client"].string ?? json["launcherMeta"]["mainClass"].stringValue
    }
    
    public static func parse(_ data: Data) throws -> [FabricManifest] {
        return try JSON(data: data).arrayValue.map(FabricManifest.init).map { $0! }
    }
}

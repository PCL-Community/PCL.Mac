//
//  NeoforgeManifest.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/17.
//

import Foundation
import SwiftyJSON

public class NeoforgeManifest {
    public let version: String
    public let installerUrl: URL
    
    public init(_ json: JSON) {
        self.version = json["version"].stringValue
        self.installerUrl = URL(string: "https://bmclapi2.bangbang93.com")!.appending(path: json["installerPath"].stringValue)
    }
    
    public static func parse(_ data: Data) throws -> [NeoforgeManifest] {
        return try JSON(data: data).arrayValue.map(NeoforgeManifest.init)
    }
}

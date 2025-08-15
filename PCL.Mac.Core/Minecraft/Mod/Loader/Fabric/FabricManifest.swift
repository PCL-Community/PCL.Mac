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
    public let loaderVersion: String
    public let stable: Bool
    
    public init(_ json: JSON) {
        loaderVersion = json["loader"]["version"].stringValue
        stable = json["loader"]["stable"].boolValue
    }
    
    public static func parse(_ data: Data) throws -> [FabricManifest] {
        return try JSON(data: data).arrayValue.map(FabricManifest.init)
    }
}

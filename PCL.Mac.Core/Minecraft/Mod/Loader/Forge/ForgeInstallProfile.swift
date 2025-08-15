//
//  ForgeInstallProfile.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/15.
//

import Foundation
import SwiftyJSON

public struct ForgeInstallProfile {
    public let path: String
    public let data: [String: String]
    public let processors: [Processor]
    public let libraries: [ClientManifest.Library]
    
    public init(json: JSON) {
        self.path = Util.toPath(mavenCoordinate: json["path"].stringValue)
        self.data = json["data"].dictionaryValue.mapValues { $0["client"].stringValue }
        self.processors = json["processors"].arrayValue.map(Processor.init(json:))
        self.libraries = json["libraries"].arrayValue.compactMap(ClientManifest.Library.init(json:))
    }
    
    public struct Processor {
        public let isAvaliableOnClient: Bool
        
        /// 已解析过的 processor jar 文件，不是 Maven 坐标
        public let jarPath: String
        
        /// 已解析过的类路径，不是 Maven 坐标
        public let classpath: [String]
        
        /// 参数列表
        public let args: [String]
        
        fileprivate init(json: JSON) {
            let sides = json["sides"].arrayValue.map { $0.stringValue }
            self.isAvaliableOnClient = sides.contains("server") && sides.count == 1 ? false : true
            self.jarPath = Util.toPath(mavenCoordinate: json["jar"].stringValue)
            self.classpath = json["classpath"].arrayValue.map { Util.toPath(mavenCoordinate: $0.stringValue) }.union([jarPath])
            self.args = json["args"].arrayValue.map { $0.stringValue }
        }
    }
}

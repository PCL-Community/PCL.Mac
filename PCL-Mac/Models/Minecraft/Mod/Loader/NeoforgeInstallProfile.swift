//
//  NeoforgeInstallProfile.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/6/18.
//

import Foundation
import SwiftyJSON

public class NeoforgeInstallProfile {
    public let data: [String: String]
    public let processors: [Processor]
    public let libraries: [Library]
    
    public init(_ json: JSON) {
        self.data = json["data"].dictionaryValue.mapValues(Data.init).mapValues { $0.client }
        self.processors = json["processors"].arrayValue.map(Processor.init).filter { $0.sides.isEmpty || $0.sides.contains("client") }
        self.libraries = json["libraries"].arrayValue.map(Library.init)
    }
    
    public class Data {
        public var client: String
        
        init(_ json: JSON) {
            let client = json["client"].stringValue
            self.client = client
        }
    }
    
    public class Processor {
        public let jarPath: String
        public let classpath: [String]
        public let args: [String]
        public let sides: [String]
        
        public init(_ json: JSON) {
            self.jarPath = Util.toPath(mavenCoordinate: json["jar"].stringValue)
            self.classpath = json["classpath"].arrayValue.map { Util.toPath(mavenCoordinate: $0.stringValue) }
            self.args = json["args"].arrayValue.map { $0.stringValue }
            self.sides = json["sides"].arrayValue.map { $0.stringValue }
        }
    }
    
    public class Library {
        public let mavenCoordinate: String
        public let downloadUrl: URL
        public let path: String
        
        public init(_ json: JSON) {
            self.mavenCoordinate = json["name"].stringValue
            self.path = json["downloads"].dictionaryValue["artifact"]!.dictionaryValue["path"]!.stringValue
            self.downloadUrl = URL(string: "https://bmclapi2.bangbang93.com/maven")!.appending(path: self.path)
        }
    }
}

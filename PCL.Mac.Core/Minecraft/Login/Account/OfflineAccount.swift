//
//  OfflineAccount.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/29.
//

import Foundation

public class OfflineAccount: Account {
    public let id: UUID
    public var uuid: UUID
    public var name: String
    
    public init(_ name: String, _ uuid: UUID? = nil) {
        self.id = .init()
        self.name = name
        self.uuid = uuid ?? UUID.nameUUIDFromBytes(Array("OfflinePlayer:\(name)".utf8))
    }
    
    public func putAccessToken(options: LaunchOptions) {
        options.accessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}

//
//  MsAccount.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/6/29.
//

import Foundation

public class MsAccount: Codable, Identifiable, Account {
    public let id: UUID
    public var uuid: UUID
    public var name: String
    
    public func getAccessToken() -> String {
        "Not implemented"
    }
}

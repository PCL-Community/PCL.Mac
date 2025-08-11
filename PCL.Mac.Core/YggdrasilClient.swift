//
//  YggdrasilClient.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/11.
//

import Foundation
import SwiftyJSON

public class YggdrasilClient {
    private let serverURL: URL
    
    public init(_ serverURL: URL) {
        self.serverURL = serverURL
    }
    
    // MARK: - 登录
    /// https://github.com/yushijinhun/authlib-injector/wiki/Yggdrasil-服务端技术规范#登录
    /// POST /authserver/authenticate
    public func authenticate(identifier: String, password: String) async throws -> AuthenticationResponse {
        let json = try await Requests.post(
            serverURL.appending(path: "/authserver/authenticate"),
            body: [
                "username": identifier,
                "password": password,
                "requestUser": true,
                "agent": [
                    "name": "Minecraft",
                    "version": 1
                ]
            ]
        ).getJSONOrThrow()
        
        if json["error"].exists() {
            err("验证服务器返回了错误: \(json["errorMessage"].stringValue) \(json["cause"].stringValue)")
            throw MyLocalizedError(reason: json["errorMessage"].stringValue)
        }
        
        return .init(json: json)
    }
    
    // MARK: - 角色属性查询
    /// https://github.com/yushijinhun/authlib-injector/wiki/Yggdrasil-服务端技术规范#查询角色属性
    /// GET /sessionserver/session/minecraft/profile/{uuid}
    public func getProfile(id: UUID) async throws -> Profile {
        return try await getProfile(id: id.uuidString.replacingOccurrences(of: "-", with: "").lowercased())
    }
    
    public func getProfile(id: String) async throws -> Profile {
        let json = try await Requests.get(serverURL.appending(path: "/sessionserver/session/minecraft/profile/\(id)")).getJSONOrThrow()
        return .init(json: json)
    }
    
    public struct AuthenticationResponse {
        public let accessToken: String
        public let clientToken: String
        public let profileName: String
        public let profileUUID: UUID
        
        init(json: JSON) {
            self.accessToken = json["accessToken"].stringValue
            self.clientToken = json["clientToken"].stringValue
            self.profileName = json["selectedProfile"]["name"].stringValue
            self.profileUUID = parseUUID(json["selectedProfile"]["id"].stringValue)
        }
    }
    
    /// 角色模型
    public struct Profile {
        public let uuid: UUID
        public let name: String
        public let properties: [String : String]
        
        init(json: JSON) {
            self.uuid = parseUUID(json["id"].stringValue)
            self.name = json["name"].stringValue
            var properties: [String : String] = [:]
            for property in json["properties"].arrayValue {
                properties[property["name"].stringValue] = property["value"].stringValue
            }
            self.properties = properties
        }
    }
    
    /// 解析无符号 UUID
    private static func parseUUID(_ uuidString: String) -> UUID {
        if let uuid = UUID(uuidString: uuidString.replacingOccurrences(
            of: #"([0-9a-fA-F]{8})([0-9a-fA-F]{4})([0-9a-fA-F]{4})([0-9a-fA-F]{4})([0-9a-fA-F]{12})"#,
            with: "$1-$2-$3-$4-$5",
            options: .regularExpression
        )) {
            return uuid
        } else {
            err("无效的 UUID: \(uuidString)")
            return UUID()
        }
    }
}

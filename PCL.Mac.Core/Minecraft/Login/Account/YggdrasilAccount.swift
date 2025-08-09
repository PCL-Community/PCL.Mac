//
//  YggdrasilAccount.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/8/25.
//

import Foundation

public class YggdrasilAccount: Account {
    public let id: UUID
    /// 账户所属验证服务器
    public let authenticationServer: URL
    
    /// 账户的标识 (如邮箱)
    public let accountIdentifier: String
    
    /// 账户所对应角色的 UUID
    public var uuid: UUID
    
    /// 账户所对应角色的名称
    public var name: String
    
    public var accessToken: String
    public var clientToken: String
    
    public init(authenticationServer: URL, accountIdentifier: String, password: String) async throws {
        self.id = UUID()
        self.authenticationServer = authenticationServer
        self.accountIdentifier = accountIdentifier
        
        let json = try await Requests.post(
            authenticationServer.appending(path: "/authserver/authenticate"),
            body: [
                "username": accountIdentifier,
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
        
        self.accessToken = json["accessToken"].stringValue
        self.clientToken = json["clientToken"].stringValue
        guard let uuid = UUID(uuidString: json["selectedProfile"]["id"].stringValue.replacingOccurrences(
            of: #"([0-9a-fA-F]{8})([0-9a-fA-F]{4})([0-9a-fA-F]{4})([0-9a-fA-F]{4})([0-9a-fA-F]{12})"#,
            with: "$1-$2-$3-$4-$5",
            options: .regularExpression
        )) else {
            err("无效的 UUID: \(json["selectedProfile"]["id"].stringValue)")
            throw MyLocalizedError(reason: "无效的 UUID: \(json["selectedProfile"]["id"].stringValue)")
        }
        self.uuid = uuid
        self.name = json["selectedProfile"]["name"].stringValue
    }
    
    public func putAccessToken(options: LaunchOptions) async {
        options.yggdrasilArguments.append("-javaagent:${authlib_injector_path}=\(authenticationServer.absoluteString)")
        if let data = await Requests.get(authenticationServer).data {
            options.yggdrasilArguments.append("-Dauthlibinjector.yggdrasil.prefetched=\(data.base64EncodedString())")
        }
        options.accessToken = accessToken
    }
}

//
//  YggdrasilAccount.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/8/25.
//

import Foundation

public class YggdrasilAccount: Account {
    public let id: UUID
    public lazy var client: YggdrasilClient = { YggdrasilClient(authenticationServer) }()
    
    /// 账户所属验证服务器
    public let authenticationServer: URL
    
    /// 验证服务器名称
    public let authenticationServerName: String
    
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
        self.authenticationServerName = try await Requests.get(authenticationServer).getJSONOrThrow()["meta"]["serverName"].stringValue
        self.accountIdentifier = accountIdentifier
        
        let client = YggdrasilClient(authenticationServer)
        let response = try await client.authenticate(identifier: accountIdentifier, password: password)
        
        self.accessToken = response.accessToken
        self.clientToken = response.clientToken
        self.uuid = response.profileUUID
        self.name = response.profileName
    }
    
    public func putAccessToken(options: LaunchOptions) async {
        options.yggdrasilArguments.append("-javaagent:${authlib_injector_path}=\(authenticationServer.absoluteString)")
        if let data = await Requests.get(authenticationServer).data {
            options.yggdrasilArguments.append("-Dauthlibinjector.yggdrasil.prefetched=\(data.base64EncodedString())")
        }
        options.accessToken = accessToken
    }
}

//
//  MsAccount.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/29.
//

import Foundation
import SwiftyJSON
import Alamofire

public class PlayerProfile: Codable {
    public let uuid: UUID
    public let name: String
    
    public init(fromResponse data: Data) {
        let json = try! JSON(data: data)
        self.uuid = UUID(uuidString: json["id"].stringValue.replacingOccurrences(
            of: "(\\w{8})(\\w{4})(\\w{4})(\\w{4})(\\w{12})",
            with: "$1-$2-$3-$4-$5",
            options: .regularExpression
        ))!
        self.name = json["name"].stringValue
    }
}

public class MsAccount: Codable, Identifiable, Account {
    public let id: UUID
    public var refreshToken: String
    public var profile: PlayerProfile
    
    public var name: String { profile.name }
    public var uuid: UUID { profile.uuid }
    
    public func refreshAccessToken() {
        if AccessTokenStorage.shared.getTokenInfo(for: id) != nil {
            debug("无需刷新 Access Token")
            return
        }
        
        Task {
            if let authToken = await MsLogin.refreshAccessToken(self.refreshToken) {
                if let _ = await MsLogin.getMinecraftAccessToken(id: id, authToken.accessToken) {
                    self.refreshToken = authToken.refreshToken
                    debug("成功刷新 Access Token")
                    return
                }
            }
            err("无法刷新 Access Token")
        }
    }
    
    public init(refreshToken: String, profile: PlayerProfile) {
        self.id = .init()
        self.refreshToken = refreshToken
        self.profile = profile
        refreshAccessToken()
    }
    
    public static func create(_ authToken: AuthToken) async -> MsAccount? {
        guard let accessToken = authToken.minecraftAccessToken else {
            return nil
        }
        
        if let data = try? await AF.request(
            "https://api.minecraftservices.com/minecraft/profile",
            method: .get,
            encoding: JSONEncoding.default,
            headers: .init(
                [.authorization("Bearer \(accessToken)")]
            )
        ).serializingResponse(using: .data).value {
            return .init(refreshToken: authToken.refreshToken, profile: .init(fromResponse: data))
        }
        return nil
    }
    
    public func getAccessToken() -> String {
        AccessTokenStorage.shared.getTokenInfo(for: id)?.accessToken ?? UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}

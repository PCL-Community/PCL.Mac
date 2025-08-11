//
//  MicrosoftAccount.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/29.
//

import Foundation
import SwiftyJSON

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

public class MicrosoftAccount: Account {
    public let id: UUID
    public var refreshToken: String
    public var profile: PlayerProfile
    public var isTokenRefreshing: Bool = false
    
    public var name: String { profile.name }
    public var uuid: UUID { profile.uuid }
    
    public func refreshAccessToken() async {
        if isTokenRefreshing { return }
        isTokenRefreshing = true
        if AccessTokenStorage.shared.getTokenInfo(for: id) != nil {
            debug("无需刷新 Access Token")
            return
        }
        
        if let authToken = try? await MsLogin.refreshAccessToken(self.refreshToken) {
            if (try? await MsLogin.getMinecraftAccessToken(id: id, authToken.accessToken)) != nil {
                self.refreshToken = authToken.refreshToken
                debug("成功刷新 Access Token")
                return
            }
        }
        err("无法刷新 Access Token")
    }
    
    enum CodingKeys: CodingKey {
        case id
        case refreshToken
        case profile
    }
    
    public init(refreshToken: String, profile: PlayerProfile) {
        self.id = .init()
        self.refreshToken = refreshToken
        self.profile = profile
    }
    
    public static func create(_ authToken: AuthToken) async -> MicrosoftAccount? {
        guard let accessToken = authToken.minecraftAccessToken else {
            return nil
        }
        
        if let data = await Requests.get(
            URL(string: "https://api.minecraftservices.com/minecraft/profile")!,
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        ).data {
            return .init(refreshToken: authToken.refreshToken, profile: .init(fromResponse: data))
        }
        return nil
    }
    
    public func putAccessToken(options: LaunchOptions) async {
        await self.refreshAccessToken()
        options.accessToken = AccessTokenStorage.shared.getTokenInfo(for: id)?.accessToken ?? UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}

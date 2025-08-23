//
//  AccountManager.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/29.
//

import Foundation
import SwiftyJSON

public protocol Account: Codable, Identifiable {
    var id: UUID { get }
    var uuid: UUID { get }
    var name: String { get }
    func putAccessToken(options: LaunchOptions) async
}

public enum AnyAccount: Account, Identifiable, Equatable {
    case offline(OfflineAccount)
    case microsoft(MicrosoftAccount)
    case yggdrasil(YggdrasilAccount)
    
    private var account: any Account {
        switch self {
        case .offline(let account): return account
        case .microsoft(let account): return account
        case .yggdrasil(let account): return account
        }
    }
    
    public var id: UUID { account.id }
    public var uuid: UUID { account.uuid }
    public var name: String { account.name }
    
    public static func == (lhs: AnyAccount, rhs: AnyAccount) -> Bool {
        lhs.id == rhs.id
    }
    
    public func putAccessToken(options: LaunchOptions) async { await account.putAccessToken(options: options) }
    
    // MARK: - Codable
    private enum CodingKeys: String, CodingKey { case type, payload }
    private enum AccountType: String, Codable { case offline, microsoft, yggdrasil }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(AccountType.self, forKey: .type) {
        case .offline:    self = .offline(try container.decode(OfflineAccount.self, forKey: .payload))
        case .microsoft:  self = .microsoft(try container.decode(MicrosoftAccount.self, forKey: .payload))
        case .yggdrasil:  self = .yggdrasil(try container.decode(YggdrasilAccount.self, forKey: .payload))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .offline(let value):
            try container.encode(AccountType.offline, forKey: .type)
            try container.encode(value, forKey: .payload)
        case .microsoft(let value):
            try container.encode(AccountType.microsoft, forKey: .type)
            try container.encode(value, forKey: .payload)
        case .yggdrasil(let value):
            try container.encode(AccountType.yggdrasil, forKey: .type)
            try container.encode(value, forKey: .payload)
        }
    }
    
    public func getSkinData() async throws -> Data {
        let url: URL
        switch self {
        case .offline(_), .microsoft(_):
            url = URL(string: "https://crafatar.com/skins/\(uuid.uuidString.replacingOccurrences(of: "-", with: "").lowercased())")!
        case .yggdrasil(let yggdrasilAccount):
            guard let textures = try await yggdrasilAccount.client.getProfile(id: yggdrasilAccount.uuid).properties["textures"] else {
                return Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAdVBMVEUAAAD///+3g2sAzMyzeV4KvLyqclkAr68ApKSbY0mUYD4ElZWPXj6QWT8FiIiBUzkAf38Denp2SzNVVVV3QjVSPYlqQDBKSkpGOqUAaGhBNZs/Pz86MYk3Nzc/KhVJJRAoKCg0JRIzJBFCHQorHg0mGgokGAjoejraAAAAAXRSTlMAQObYZgAAAtFJREFUeNrtlm132jAMhelKFWuOHdr1hYYkZcbz//+Ju5LjsXRwEujHcSNsOefc50gmEK+KYgyIEJtRq0sVw4AQwBN0DQBmudyTyl0OgDvgcz0g5iZcbuFyQAggxGFoXAO5+nKA7AFUN/m6GAB3BCM29QfU1MuN4kwyDhAIWASZgmZxye7HlEJAwC9XEhxikPvDot6jDLz+tib+qeshBC0D1FmAVpxiZFqviYjVldvQRuYB+vhxorsX4pc7Suz0VkgKCku+/5AYInp9JWIoaf0pCSTOAlJMjuvmu6s/np8PSJqaHW4KIC4BNA5+FuPh44Dv32HBTh7HX9DCX2UH9f1+X9b3xMDSfTeq3K+qyjARnQTs933/B8AO4pMAAvxsBbOABwDmKzjfgpEWPlfQtl273W47TG2L2UKVIWYyVc4NRlgrZJg2kCyOgO4I2ELWe1tVlgij5pDa1Q/A+/sG6REwGtsC8I+P3sAiA3IlWAm1G6sALE4DEI9QMUluxIXPZtQ7JPMEIG0IoYPE5I0C/AiwAmFmJ5cKi2kFCLgVJGV7YxQwtqAFERETY4CboCkAKrOHrJSNbSi5LJkyQgGII6CdAiw8Xso2xkquACMAlTYyqaBTo2CQQdZbhNEiNEMCv2diBUBTwNtbN+pNBZcyYLQiccPvCYBCmAD6HVw/xLqTdJe/DNTjYZMEHSHZZgBnAP8N6PudGHc9hBEA7Wnbep/3BSyMTPDmLVDE6qb/Ug9ZlYEqJKubbvqk2ZetvJOIiCW/5sChAMdEX6jgoSLoKxUYx4taKOeFti0v3Q1UXu2ieUBxdgBB+jpXgo7LAJ0A2iPAZjNiaQUFgKycB4rG/4OiI/DcecGJWC6Vm68AZkgrkJxhzUeDrMtagASgdqUwLd9ESABOASqdFjxE5UlABmnvap8BnDsvFL/YZwCnzwsK4ALgGcCJ8wLnTUCQTP/8Hn4DsAh5tPm8HxQAAAAASUVORK5CYII=")!
            }
            let json = try JSON(data: Data(base64Encoded: textures) ?? .init())
            url = URL(string: json["textures"]["SKIN"]["url"].stringValue)!
        }
        
        return try await Requests.get(url).getDataOrThrow()
    }
}

public class AccountManager: ObservableObject {
    public static let shared: AccountManager = .init()
    
    @CodableAppStorage("accounts") public var accounts: [AnyAccount] = []
    
    @CodableAppStorage("accountId") public var accountId: UUID? = nil
    
    public func getAccount() -> AnyAccount? {
        if accountId == nil {
            if let id = accounts.first?.id {
                accountId = id
            } else {
                return nil
            }
        }
        
        if let account = accounts.first(where: { $0.id == accountId }) {
            return account
        }
        
        warn("accountId 对应的账号不存在！")
        accountId = nil
        return nil
    }
}

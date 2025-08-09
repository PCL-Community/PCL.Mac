//
//  AccountManager.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/29.
//

import Foundation

public protocol Account: Codable {
    var uuid: UUID { get }
    var name: String { get }
    func putAccessToken(options: LaunchOptions) async
}

public enum AnyAccount: Account, Identifiable, Equatable {
    case offline(OfflineAccount)
    case microsoft(MicrosoftAccount)
    case yggdrasil(YggdrasilAccount)
    
    public var id: UUID {
        switch self {
        case .offline(let offlineAccount):
            offlineAccount.id
        case .microsoft(let msAccount):
            msAccount.id
        case .yggdrasil(let yggdrasilAccount):
            yggdrasilAccount.id
        }
    }
    
    public var uuid: UUID {
        switch self {
        case .offline(let offlineAccount):
            offlineAccount.uuid
        case .microsoft(let msAccount):
            msAccount.uuid
        case .yggdrasil(let yggdrasilAccount):
            yggdrasilAccount.uuid
        }
    }
    
    public var name: String {
        switch self {
        case .offline(let offlineAccount):
            offlineAccount.name
        case .microsoft(let msAccount):
            msAccount.name
        case .yggdrasil(let yggdrasilAccount):
            yggdrasilAccount.name
        }
    }
    
    public static func == (lhs: AnyAccount, rhs: AnyAccount) -> Bool {
        lhs.id == rhs.id
    }
    
    public func putAccessToken(options: LaunchOptions) async {
        switch self {
        case .offline(let offlineAccount):
            offlineAccount.putAccessToken(options: options)
        case .microsoft(let msAccount):
            await msAccount.putAccessToken(options: options)
        case .yggdrasil(let yggdrasilAccount):
            await yggdrasilAccount.putAccessToken(options: options)
        }
    }
    
    // MARK: - Codable
    private enum CodingKeys: String, CodingKey { case type, payload }
    private enum AccountType: String, Codable { case offline, microsoft, yggdrasil }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(AccountType.self, forKey: .type)
        switch type {
        case .offline:
            let value = try container.decode(OfflineAccount.self, forKey: .payload)
            self = .offline(value)
        case .microsoft:
            let value = try container.decode(MicrosoftAccount.self, forKey: .payload)
            self = .microsoft(value)
        case .yggdrasil:
            let value = try container.decode(YggdrasilAccount.self, forKey: .payload)
            self = .yggdrasil(value)
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

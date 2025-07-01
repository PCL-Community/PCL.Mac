//
//  AccountManager.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/6/29.
//

import Foundation

public protocol Account: Codable {
    var uuid: UUID { get }
    var name: String { get }
    func getAccessToken() -> String
}

public enum AnyAccount: Account, Identifiable, Equatable {
    case offline(OfflineAccount)
    case microsoft(MsAccount)
    
    public var id: UUID {
        switch self {
        case .offline(let offlineAccount):
            offlineAccount.id
        case .microsoft(let msAccount):
            msAccount.id
        }
    }
    
    public var uuid: UUID {
        switch self {
        case .offline(let offlineAccount):
            offlineAccount.uuid
        case .microsoft(let msAccount):
            msAccount.uuid
        }
    }
    
    public var name: String {
        switch self {
        case .offline(let offlineAccount):
            offlineAccount.name
        case .microsoft(let msAccount):
            msAccount.name
        }
    }
    
    public static func == (lhs: AnyAccount, rhs: AnyAccount) -> Bool {
        lhs.id == rhs.id
    }
    
    public func getAccessToken() -> String {
        switch self {
        case .offline(let offlineAccount):
            offlineAccount.getAccessToken()
        case .microsoft(let msAccount):
            msAccount.getAccessToken()
        }
    }
    
    // MARK: - Codable
    private enum CodingKeys: String, CodingKey { case type, payload }
    private enum AccountType: String, Codable { case offline, microsoft }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(AccountType.self, forKey: .type)
        switch type {
        case .offline:
            let value = try container.decode(OfflineAccount.self, forKey: .payload)
            self = .offline(value)
        case .microsoft:
            let value = try container.decode(MsAccount.self, forKey: .payload)
            self = .microsoft(value)
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
        }
    }
}

public class AccountManager: ObservableObject {
    public static let shared: AccountManager = .init()
    
    @CodableAppStorage("accounts") public var accounts: [AnyAccount] = [
        .offline(.init("PCL_Mac"))
    ]
    
    @CodableAppStorage("accountId") public var accountId: UUID? = nil
    
    public func getAccount() -> Account? {
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

//
//  AccessTokenStorage.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/1.
//

import Foundation

struct AccessTokenInfo: Codable, Identifiable {
    let id: UUID
    let accessToken: String
    let expiresAt: Date

    init(id: UUID, accessToken: String, expiriesIn: Int) {
        self.id = id
        self.accessToken = accessToken
        self.expiresAt = Date().addingTimeInterval(TimeInterval(expiriesIn))
    }

    var isExpired: Bool {
        expiresAt <= Date()
    }
}

final class AccessTokenStorage: ObservableObject {
    static let shared = AccessTokenStorage()

    @CodableAppStorage("accessTokens") private var accessTokens: [UUID: AccessTokenInfo] = [:]

    private init() {
        removeExpiredTokens()
    }

    func add(id: UUID, accessToken: String, expiriesIn: Int) {
        let info = AccessTokenInfo(id: id, accessToken: accessToken, expiriesIn: expiriesIn)
        accessTokens[id] = info
    }

    func getTokenInfo(for id: UUID) -> AccessTokenInfo? {
        accessTokens[id]
    }

    var allTokens: [AccessTokenInfo] {
        Array(accessTokens.values)
    }

    func removeExpiredTokens() {
        let now = Date()
        accessTokens = accessTokens.filter { $0.value.expiresAt > now }
    }
}

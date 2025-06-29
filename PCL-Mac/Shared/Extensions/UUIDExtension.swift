//
//  UUIDExtension.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/6/29.
//

import Foundation
import CryptoKit

public extension UUID {
    static func nameUUIDFromBytes(_ bytes: [UInt8]) -> UUID {
        let hash = Insecure.MD5.hash(data: bytes)
        var hashBytes = Array(hash)
        hashBytes[6] = (hashBytes[6] & 0x0F) | 0x30
        hashBytes[8] = (hashBytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            hashBytes[0], hashBytes[1], hashBytes[2], hashBytes[3],
            hashBytes[4], hashBytes[5], hashBytes[6], hashBytes[7],
            hashBytes[8], hashBytes[9], hashBytes[10], hashBytes[11],
            hashBytes[12], hashBytes[13], hashBytes[14], hashBytes[15]
        ))
    }
}

//
//  DateExtension.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/1.
//

import Foundation

extension Date: @retroactive RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: RawValue) {
        guard let data = rawValue.data(using: .utf8),
              let date = try? JSONDecoder().decode(Date.self, from: data) else {
            return nil
        }
        self = date
    }
    
    public var rawValue: RawValue {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return ""
        }
        return string
    }
}

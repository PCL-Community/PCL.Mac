//
//  Hint.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/26.
//

import Foundation

struct Hint: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let type: HintType
}

enum HintType {
    case info, finish, critical
}

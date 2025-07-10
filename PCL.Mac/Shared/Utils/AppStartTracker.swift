//
//  AppStartTracker.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/11.
//

import Foundation

final class AppStartTracker {
    static let shared = AppStartTracker()
    let launchTime: TimeInterval
    var finished = false
    private init() {
        launchTime = Date().timeIntervalSince1970
    }
}

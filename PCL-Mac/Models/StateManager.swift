//
//  StateManager.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/6/20.
//

import SwiftUI

/// 负责保存页面数据的类
class StateManager: ObservableObject {
    static let shared = StateManager()
    
    @Published var modSearch: ModSearchViewState = .init()
    @Published var newAccount: NewAccountViewState = .init()
}

//
//  MultiplayerView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/18.
//

import SwiftUI

struct MultiplayerView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    
    var body: some View {
        VStack {
            Text("Multiplayer view")
        }
        .onAppear {
            dataManager.leftTab(0) { EmptyView() }
        }
    }
}

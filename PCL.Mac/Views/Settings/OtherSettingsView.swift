//
//  OtherSettingsView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/21.
//

import SwiftUI

struct OtherSettingsView: View {
    @ObservedObject private var dataManager = DataManager.shared
    
    var body: some View {
        HStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack {
                    MyButtonComponent(text: "打开日志") {
                        NSWorkspace.shared.activateFileViewerSelecting([SharedConstants.shared.applicationLogUrl])
                    }
                    .frame(height: 40)
                    .padding()
                    .padding(.bottom, -23)
                }
                .scrollIndicators(.never)
            }
        }
    }
}

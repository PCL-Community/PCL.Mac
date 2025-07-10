//
//  AnnouncementHistoryView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/5.
//

import SwiftUI

struct AnnouncementHistoryView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject private var announcementManager: AnnouncementManager = .shared
    
    var body: some View {
        ScrollView {
            Text("仅显示最近 10 条公告")
                .font(.custom("PCL English", size: 14))
                .foregroundStyle(Color("TextColor"))
                .padding()
            VStack {
                ForEach(announcementManager.history) { announcement in
                    announcement.createView()
                        .padding()
                }
            }
            .padding(.bottom, 25)
        }
        .scrollIndicators(.never)
        .onAppear {
            dataManager.leftTab(0) { EmptyView() }
            announcementManager.loadHistory()
        }
    }
}

//
//  OtherSettingsView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/21.
//

import SwiftUI

struct OtherSettingsView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @ObservedObject private var settings: AppSettings = .shared
    
    var body: some View {
        HStack {
            ScrollView(.vertical, showsIndicators: true) {
                StaticMyCard(title: "下载") {
                    VStack {
                        OptionStack("文件下载源") {
                            MyPicker(selected: $settings.fileDownloadSource, entries: [.mirror, .both, .official]) { option in
                                switch option {
                                case .official: "尽量使用官方源"
                                case .both: "优先使用官方源，在加载缓慢时换用镜像源"
                                case .mirror: "尽量使用镜像源"
                                }
                            }
                        }
                        
                        OptionStack("版本列表源") {
                            MyPicker(selected: $settings.versionManifestSource, entries: [.mirror, .both, .official]) { option in
                                switch option {
                                case .official: "尽量使用官方源"
                                case .both: "优先使用官方源，在加载缓慢时换用镜像源"
                                case .mirror: "尽量使用镜像源（可能缺少刚刚更新的版本）"
                                }
                            }
                        }
                    }
                    .padding(18)
                }
                .padding()
                
                StaticMyCard(index: 1, title: "帮助") {
                    HStack {
                        MyButton(text: "打开日志") {
                            NSWorkspace.shared.activateFileViewerSelecting([SharedConstants.shared.logURL])
                        }
                        .frame(width: 140, height: 35)
                        
                        Spacer()
                    }
                    .padding()
                }
                .padding()
            }
        }
    }
}

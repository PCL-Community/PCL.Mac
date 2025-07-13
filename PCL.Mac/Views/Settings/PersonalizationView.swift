//
//  PersonalizationView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/21.
//

import SwiftUI

struct PersonalizationView: View {
    @ObservedObject private var settings: AppSettings = .shared
    
    var body: some View {
        ScrollView {
            StaticMyCardComponent(title: "配色方案") {
                HStack {
                    MyComboBoxComponent(
                        options: [ColorSchemeOption.light, ColorSchemeOption.dark, ColorSchemeOption.system],
                        selection: $settings.colorScheme,
                        label: { $0.getLabel() }) { content in
                            HStack(spacing: 120) {
                                content
                            }
                        }
                        .onChange(of: settings.colorScheme) { _ in
                            settings.updateColorScheme()
                        }
                    Spacer()
                }
                .padding()
            }
            .padding()
            
            StaticMyCardComponent(index: 1, title: "窗口按钮样式") {
                HStack {
                    MyComboBoxComponent(
                        options: [WindowControlButtonStyle.pcl, WindowControlButtonStyle.macOS],
                        selection: $settings.windowControlButtonStyle,
                        label: { $0.getLabel() }) { content in
                            HStack(spacing: 120) {
                                content
                            }
                        }
                    Spacer()
                }
                .padding()
            }
            .padding()

            StaticMyCardComponent(index: 2, title: "界面效果") {
                VStack(spacing: 16) {
                    // Beta UI开关
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Beta UI")
                                .font(.custom("PCL English", size: 14))
                                .fontWeight(.medium)
                            Text("启用实验性的卡片悬停效果（蓝色边框、文字加粗、缩放动画）")
                                .font(.custom("PCL English", size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.enableBetaUI)
                            .toggleStyle(SwitchToggleStyle())
                    }
                }
                .padding()
            }
            .padding()
        }
        .scrollIndicators(.never)
    }
}

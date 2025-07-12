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
            
            StaticMyCardComponent(title: "窗口按钮样式") {
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
        }
        .scrollIndicators(.never)
    }
}

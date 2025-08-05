//
//  PersonalizationView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/21.
//

import SwiftUI

struct PersonalizationView: View {
    @ObservedObject private var settings: AppSettings = .shared
    @State private var selectedTheme: ThemeInfo = .init(id: "pcl", name: "PCL")
    
    var body: some View {
        ScrollView {
            StaticMyCardComponent(title: "基础") {
                VStack {
                    ZStack(alignment: .topLeading) {
                        Spacer()
                        MyComboBoxComponent(
                            options: ThemeParser.shared.themes,
                            selection: $selectedTheme,
                            label: { $0.name }) { content in
                                HStack(spacing: 40) {
                                    content
                                }
                            }
                            .onChange(of: selectedTheme) { _ in
                                settings.themeId = selectedTheme.id
                            }
                            .padding()
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(settings.theme.getAccentColor(), style: .init(lineWidth: 1))
                    }
                    .frame(height: 150)
                    .padding(.bottom)
                    
                    HStack {
                        Text("配色方案")
                            .padding(.trailing, 10)
                        MyComboBoxComponent(
                            options: [ColorSchemeOption.light, ColorSchemeOption.dark, ColorSchemeOption.system],
                            selection: $settings.colorScheme,
                            label: { $0.getLabel() }) { content in
                                HStack(spacing: 40) {
                                    content
                                }
                            }
                            .onChange(of: settings.colorScheme) { _ in
                                settings.updateColorScheme()
                            }
                        Spacer()
                    }
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
        }
        .scrollIndicators(.never)
        .font(.custom("PCL English", size: 14))
        .foregroundStyle(.text)
        .onAppear {
            self.selectedTheme = ThemeParser.shared.themes.find { $0.id == settings.themeId } ?? .init(id: "pcl", name: "PCL")
        }
    }
}

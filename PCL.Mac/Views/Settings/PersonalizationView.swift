//
//  PersonalizationView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/21.
//

import SwiftUI

struct PersonalizationView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject private var settings: AppSettings = .shared
    @State private var selectedTheme: ThemeInfo = .init(id: "pcl", name: "PCL")
    @State private var themes: [ThemeInfo] = []
    
    var body: some View {
        ScrollView {
            StaticMyCard(title: "基础") {
                VStack(spacing: 15) {
                    ZStack(alignment: .topLeading) {
                        Spacer()
                        MyComboBox(
                            options: themes,
                            selection: $selectedTheme,
                            label: { $0.name }) { content in
                                HStack(spacing: 120) {
                                    content
                                }
                            }
                            .onChange(of: selectedTheme) {
                                settings.themeId = selectedTheme.id
                            }
                            .padding()
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(settings.theme.getAccentColor(), style: .init(lineWidth: 1))
                    }
                    
                    HStack {
                        MyButton(text: "解锁更多主题") {
                            dataManager.router.append(.themeUnlock)
                        }
                        .frame(height: 35)
                        .fixedSize(horizontal: true, vertical: false)
                        Spacer()
                    }
                    
                    OptionStack("配色方案") {
                        MyComboBox(
                            options: [ColorSchemeOption.light, ColorSchemeOption.dark, ColorSchemeOption.system],
                            selection: $settings.colorScheme,
                            label: { $0.getLabel() }
                        ) { content in
                            HStack(spacing: 40) {
                                content
                            }
                        }
                        .onChange(of: settings.colorScheme) {
                            settings.updateColorScheme()
                        }
                    }
                }
                .padding()
            }
            .padding()
            
            StaticMyCard(index: 1, title: "其它") {
                VStack {
                    OptionStack("窗口按钮样式") {
                        MyComboBox(
                            options: [WindowControlButtonStyle.pcl, WindowControlButtonStyle.macOS],
                            selection: $settings.windowControlButtonStyle,
                            label: { $0.getLabel() }
                        ) { content in
                            HStack(spacing: 120) {
                                content
                            }
                        }
                    }
                    .padding()
                    OptionStack("超薄材质") {
                        Toggle("", isOn: $settings.useUltraThinMaterial)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .scrollIndicators(.never)
        .font(.custom("PCL English", size: 14))
        .foregroundStyle(.text)
        .onAppear {
            self.themes = ThemeParser.shared.themes.filter(ThemeOwnershipChecker.shared.isUnlocked(_:))
            self.selectedTheme = ThemeParser.shared.themes.find { $0.id == settings.themeId } ?? selectedTheme
        }
    }
}

struct OptionStack<Content: View>: View {
    private let label: String
    private let content: () -> Content
    
    init(_ label: String, @ViewBuilder _ content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.custom("PCL English", size: 14))
                .foregroundStyle(Color("TextColor"))
                .frame(width: 120, alignment: .leading)
            
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

//
//  ThemeUnlockView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/5/25.
//

import SwiftUI
import AppKit

struct ThemeUnlockView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @State private var code: String = ""
    @State private var isHovered: Bool = false
    private let deviceHash: String = ThemeOwnershipChecker.shared.getDeviceHash()
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            TitlelessMyCardComponent {
                VStack(spacing: 24) {
                    // 哈希展示区
                    VStack(alignment: .leading, spacing: 10) {
                        Text("你的设备哈希：")
                            .foregroundStyle(Color("TextColor"))
                        Text(deviceHash)
                            .font(.custom("PCL English", size: 18))
                            .foregroundStyle(Color("TextColor"))
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isHovered ? AppSettings.shared.theme.getAccentColor() : Color.gray, lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(deviceHash, forType: .string)
                                hint("复制成功！", .finish)
                            }
                            .onHover { isHovered in
                                self.isHovered = isHovered
                            }
                            .animation(.easeInOut(duration: 0.2), value: isHovered)
                    }
                    MyTextFieldComponent(text: $code, placeholder: "解锁码")
                        .onSubmit {
                            if AppSettings.shared.usedThemeCodes.contains(code) {
                                hint("你已经使用过这个解锁码了！", .critical)
                            } else {
                                if let theme = ThemeOwnershipChecker.shared.tryUnlock(code: code) {
                                    AppSettings.shared.usedThemeCodes.append(code)
                                    if let theme = ThemeParser.shared.themes.find({ $0.id == theme }) {
                                        ThemeOwnershipChecker.shared.unlockedThemes.append(theme.id)
                                        hint("你已成功解锁主题：\(theme.name)！", .finish)
                                    }
                                } else {
                                    hint("无效的解锁码！", .critical)
                                }
                            }
                            code.removeAll()
                        }
                        .frame(height: 54)
                }
                .padding()
                .font(.custom("PCL English", size: 14))
                .foregroundStyle(Color("TextColor"))
            }
            .padding(.top, 24)
            .padding(.horizontal)
        }
        .onAppear {
            dataManager.leftTab(0) { EmptyView() }
        }
    }
}

#Preview {
    ThemeUnlockView()
}

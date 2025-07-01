//
//  NewAccountView.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/6/30.
//

import SwiftUI

fileprivate struct MenuItemComponent: View {
    @ObservedObject private var state: NewAccountViewState = StateManager.shared.newAccount
    
    @State private var isHovered: Bool = false
    
    let value: NewAccountViewState.PageType
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(state.type == value ? Color(hex: 0x1370F3) : isHovered ? Color(hex: 0x1370F3, alpha: 0.5) : Color("MyCardBackgroundColor"))
                .animation(.easeInOut(duration: 0.2), value: state.type)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
            Text(value == .microsoft ? "正版" : "离线")
                .font(.custom("PCL English", size: 14))
                .foregroundStyle(Color("TextColor"))
                .padding(5)
        }
        .fixedSize()
        .onTapGesture {
            state.type = value
        }
        .onHover { hover in
            self.isHovered = hover
        }
    }
}

class NewAccountViewState: ObservableObject {
    enum PageType {
        case offline, microsoft
    }
    
    @Published var type: PageType = .offline
    @Published var playerName: String = ""
}

struct NewAccountView: View {
    @ObservedObject private var state: NewAccountViewState = StateManager.shared.newAccount
    
    var body: some View {
        VStack {
            TitlelessMyCardComponent {
                HStack {
                    MenuItemComponent(value: .offline)
                    MenuItemComponent(value: .microsoft)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            
            switch state.type {
            case .offline:
                NewOfflineAccountView()
            case .microsoft:
                Spacer()
            }
        }
    }
}

fileprivate struct NewOfflineAccountView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject private var accountManager: AccountManager = .shared
    @ObservedObject private var state: NewAccountViewState = StateManager.shared.newAccount
    
    @State private var warningText: String = ""
    
    var body: some View {
        VStack {
            StaticMyCardComponent(title: "离线账号") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(warningText)
                        .foregroundStyle(Color(hex: 0xFF2B00))
                    MyTextFieldComponent(text: $state.playerName, placeholder: "玩家名")
                        .onChange(of: state.playerName) { name in
                            if name.count < 3 || name.count > 16 {
                                warningText = "玩家名长度需在 3~16 个字符之间！"
                                return
                            }
                            
                            if name.wholeMatch(of: /^(?:[A-Za-z0-9_]+)$/) == nil {
                                warningText = "玩家名仅可包含数字、大小写字母和下划线！"
                                return
                            }
                            
                            warningText = ""
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Spacer()
                        MyButtonComponent(text: "添加") {
                            if warningText != "" {
                                HintManager.default.add(.init(text: warningText, type: .critical))
                                return
                            }
                            
                            accountManager.accounts.removeAll(where: { account in
                                if case .offline(let offlineAccount) = account {
                                    return offlineAccount.name == state.playerName
                                }
                                return false
                            })
                            
                            let account: AnyAccount = .offline(.init(state.playerName))
                            accountManager.accounts.append(account)
                            accountManager.accountId = account.id
                            
                            HintManager.default.add(.init(text: "添加成功", type: .finish))
                            dataManager.router.removeLast()
                            dataManager.router.append(.accountList)
                        }
                        .fixedSize()
                    }
                }
                .font(.custom("PCL English", size: 14))
                .foregroundStyle(Color("TextColor"))
            }
            .padding()
            Spacer()
        }
    }
}


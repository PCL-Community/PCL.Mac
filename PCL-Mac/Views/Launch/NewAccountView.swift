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
    
    @Published var type: PageType? = nil
    @Published var playerName: String = ""
}

struct NewAccountView: View {
    @ObservedObject private var state: NewAccountViewState = StateManager.shared.newAccount
    
    var body: some View {
        switch state.type {
        case .offline:
            NewOfflineAccountView()
        case .microsoft:
            Spacer()
        default:
            VStack {
                StaticMyCardComponent(title: "登录方式") {
                    VStack {
                        AuthMethodComponent(type: .microsoft)
                        AuthMethodComponent(type: .offline)
                    }
                }
                .padding()
                Spacer()
            }
        }
    }
}

fileprivate struct AuthMethodComponent: View {
    let type: NewAccountViewState.PageType
    
    var body: some View {
        MyListItemComponent {
            HStack {
                Image("\(String(describing: type).capitalized)LoginIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25)
                VStack(alignment: .leading) {
                    let title = switch type {
                    case .offline:
                        "离线验证"
                    case .microsoft:
                        "正版验证"
                    }
                    let desc = switch type {
                    case .offline:
                        "可自定义玩家名，可能无法加入部分服务器"
                    case .microsoft:
                        "需要购买 Minecraft"
                    }
                    
                    Text(title)
                        .foregroundStyle(Color("TextColor"))
                    Text(desc)
                        .foregroundStyle(Color(hex: 0x8C8C8C))
                }
                .font(.custom("PCL English", size: 14))
                Spacer()
            }
            .frame(height: 32)
            .padding(5)
        }
        .onTapGesture {
            StateManager.shared.newAccount.type = type
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
                            warningText = checkPlayerName(name)
                        }
                        .onSubmit(addAccount)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Spacer()
                        MyButtonComponent(text: "取消") {
                            state.type = nil
                        }
                        .fixedSize()
                        
                        MyButtonComponent(text: "添加", action: addAccount)
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
    
    private func addAccount() {
        warningText = checkPlayerName(state.playerName)
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
        StateManager.shared.newAccount = .init()
    }
    
    private func checkPlayerName(_ name: String) -> String {
        if name.count < 3 || name.count > 16 {
            return "玩家名长度需在 3~16 个字符之间！"
        }
        
        if name.wholeMatch(of: /^(?:[A-Za-z0-9_]+)$/) == nil {
            return "玩家名仅可包含数字、大小写字母和下划线！"
        }
        return ""
    }
}


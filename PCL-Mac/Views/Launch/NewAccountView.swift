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
    @Published var authToken: Holder<AuthToken> = .init(object: nil)
    @Published var isSigningIn: Bool = false
}

struct NewAccountView: View {
    @ObservedObject private var state: NewAccountViewState = StateManager.shared.newAccount
    
    var body: some View {
        Group {
            switch state.type {
            case .offline:
                NewOfflineAccountView()
                    .transition(.move(edge: .trailing))
            case .microsoft:
                NewMicrosoftAccountView()
                    .transition(.move(edge: .trailing))
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
                .transition(.move(edge: .leading))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: state.type)
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

// MARK: - 添加离线账号页面
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
                        MyButtonComponent(text: "购买 Minecraft") {
                            NSWorkspace.shared.open(URL(string: "https://www.xbox.com/zh-cn/games/store/minecraft-java-bedrock-edition-for-pc/9nxp44l49shj")!)
                        }
                        .fixedSize()
                        
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

// MARK: - 添加正版账号页面
fileprivate struct NewMicrosoftAccountView: View {
    @ObservedObject private var state: NewAccountViewState = StateManager.shared.newAccount
    
    var body: some View {
        VStack {
            StaticMyCardComponent(title: "正版账号") {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("点击登录后会自动跳转到微软登录页面")
                        Text("请将剪切板中的内容粘贴至页面的输入框内，并登录您购买 Minecraft 时的微软账号")
                        Text("登录后出现“PCL-CE”而非“PCL-Mac”是正常的，因为 PCL-Mac 还没有自己的 Client ID qwq")
                    }
                    .font(.custom("PCL English", size: 14))
                    .foregroundStyle(Color("TextColor"))
                    .padding()
                    
                    HStack {
                        MyButtonComponent(text: "取消") {
                            state.type = nil
                        }
                        MyButtonComponent(text: "购买 Minecraft") {
                            NSWorkspace.shared.open(URL(string: "https://www.xbox.com/zh-cn/games/store/minecraft-java-bedrock-edition-for-pc/9nxp44l49shj")!)
                        }
                        MyButtonComponent(text: "登录") {
                            if !NetworkTest.shared.hasNetworkConnection() {
                                HintManager.default.add(.init(text: "请先联网！", type: .critical))
                                return
                            }
                            
                            if state.isSigningIn { return }
                            state.isSigningIn = true
                            Task {
                                guard let authToken = await MsLogin.signIn() else {
                                    HintManager.default.add(.init(text: "登录失败！", type: .critical))
                                    return
                                }
                                
                                DispatchQueue.main.async {
                                    state.authToken.setObject(authToken)
                                }
                                
                                HintManager.default.add(.init(text: "登录成功！正在检测你是否拥有 Minecraft……", type: .finish))
                                if await MsLogin.hasMinecraftGame(authToken) {
                                    HintManager.default.add(.init(text: "你购买了 Minecraft！正在保存账号数据……", type: .finish))
                                    if let msAccount = await MsAccount.create(authToken) {
                                        DispatchQueue.main.async { AccountManager.shared.accounts.append(.microsoft(msAccount)) }
                                        HintManager.default.add(.init(text: "登录成功！", type: .finish))
                                    } else {
                                        HintManager.default.add(.init(text: "在创建账号实例时发生错误", type: .critical))
                                    }
                                    DispatchQueue.main.async { StateManager.shared.newAccount = .init() }
                                } else {
                                    HintManager.default.add(.init(text: "你还没有购买 Minecraft！", type: .critical))
                                }
                            }
                        }
                    }
                    .frame(height: 40)
                }
            }
            .padding()
            
            Spacer()
        }
    }
}

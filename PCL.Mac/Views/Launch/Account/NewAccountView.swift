//
//  NewAccountView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/30.
//

import SwiftUI

class NewAccountViewState: ObservableObject {
    enum PageType {
        case offline, microsoft, yggdrasil
    }
    
    @Published var type: PageType? = nil
    @Published var playerName: String = ""
    @Published var authToken: Holder<AuthToken> = .init(object: nil)
    @Published var isSigningIn: Bool = false
}

struct NewAccountView: View {
    @ObservedObject private var state: NewAccountViewState = StateManager.shared.newAccount
    
    @State private var isAppeared: Bool = false
    
    var body: some View {
        VStack {
            switch state.type {
            case .offline:
                NewOfflineAccountView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .microsoft:
                NewMicrosoftAccountView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .yggdrasil:
                NewYggdrasilAccountView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            default:
                Group {
                    let card = StaticMyCard(title: "登录方式") {
                        VStack(spacing: 0) {
                            AuthMethodComponent(type: .microsoft)
                            AuthMethodComponent(type: .offline)
                            AuthMethodComponent(type: .yggdrasil)
                        }
                    }
                    if isAppeared { card.noAnimation() } else { card }
                }
                .padding()
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
            Spacer()
        }
        .onChange(of: state.type) {
            isAppeared = true
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: state.type)
    }
}

fileprivate struct AuthMethodComponent: View {
    let type: NewAccountViewState.PageType
    
    var body: some View {
        MyListItem {
            HStack {
                Image("\(String(describing: type).capitalized)LoginIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25)
                VStack(alignment: .leading) {
                    let title = switch type {
                    case .offline: "离线登录"
                    case .microsoft: "正版验证"
                    case .yggdrasil: "外置登录"
                    }
                    let desc = switch type {
                    case .offline: "可自定义玩家名，可能无法加入部分服务器"
                    case .microsoft: "需要购买 Minecraft"
                    case .yggdrasil: "添加外置登录账号（如 LittleSkin）"
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
        StaticMyCard(title: "离线账号") {
            VStack(alignment: .leading, spacing: 10) {
                if !warningText.isEmpty {
                    MyTip(text: warningText, color: .red)
                }
                MyTextField(text: $state.playerName, placeholder: "玩家名")
                    .onChange(of: state.playerName) {
                        warningText = checkPlayerName(state.playerName)
                    }
                    .onSubmit(addAccount)
                HStack {
                    Spacer()
                    MyButton(text: "购买 Minecraft") {
                        NSWorkspace.shared.open(URL(string: "https://www.xbox.com/zh-cn/games/store/minecraft-java-bedrock-edition-for-pc/9nxp44l49shj")!)
                    }
                    .fixedSize()
                    
                    MyButton(text: "取消") {
                        state.type = nil
                    }
                    .fixedSize()
                    
                    MyButton(text: "添加", action: addAccount)
                        .fixedSize()
                }
            }
            .font(.custom("PCL English", size: 14))
            .foregroundStyle(Color("TextColor"))
        }
        .noAnimation()
        .padding()
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
        StaticMyCard(title: "正版账号") {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("点击登录后会自动跳转到微软登录页面")
                    Text("请将剪切板中的内容粘贴至页面的输入框内，并登录您购买 Minecraft 时的微软账号")
                    Text("登录后出现“PCL-CE”而非“PCL.Mac”是正常的，因为 PCL.Mac 还没有自己的 Client ID qwq")
                }
                .font(.custom("PCL English", size: 14))
                .foregroundStyle(Color("TextColor"))
                .padding()
                
                HStack {
                    Spacer()
                    MyButton(text: "取消") {
                        state.type = nil
                    }
                    .frame(height: 35)
                    .fixedSize(horizontal: true, vertical: false)
                    MyButton(text: "购买 Minecraft") {
                        NSWorkspace.shared.open(URL(string: "https://www.xbox.com/zh-cn/games/store/minecraft-java-bedrock-edition-for-pc/9nxp44l49shj")!)
                    }
                    .frame(height: 35)
                    .fixedSize(horizontal: true, vertical: false)
                    MyButton(text: "登录") {
                        if !NetworkTest.shared.hasNetworkConnection() {
                            HintManager.default.add(.init(text: "请先联网！", type: .critical))
                            return
                        }
                        
                        if state.isSigningIn { return }
                        state.isSigningIn = true
                        Task {
                            await signIn()
                        }
                    }
                    .frame(height: 35)
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
        .noAnimation()
        .padding()
    }
    
    private func signIn() async {
        do {
            guard let authToken = try await MsLogin.signIn() else {
                HintManager.default.add(.init(text: "登录失败！", type: .critical))
                return
            }
            
            DispatchQueue.main.async {
                state.authToken.setObject(authToken)
            }
            
            HintManager.default.add(.init(text: "登录成功！正在检测你是否拥有 Minecraft……", type: .finish))
            if try await MsLogin.hasMinecraftGame(authToken) {
                HintManager.default.add(.init(text: "你购买了 Minecraft！正在保存账号数据……", type: .finish))
                if let msAccount = await MicrosoftAccount.create(authToken) {
                    DispatchQueue.main.async { AccountManager.shared.accounts.append(.microsoft(msAccount)) }
                    HintManager.default.add(.init(text: "登录成功！", type: .finish))
                    AppSettings.shared.hasMicrosoftAccount = true
                } else {
                    HintManager.default.add(.init(text: "在创建账号实例时发生错误", type: .critical))
                }
                DispatchQueue.main.async { StateManager.shared.newAccount = .init() }
            } else {
                HintManager.default.add(.init(text: "你还没有购买 Minecraft！", type: .critical))
            }
        } catch {
            err(error.localizedDescription)
            PopupManager.shared.show(.init(.error, "登录时发生错误", "\(error.localizedDescription)\n请不要退出启动器，在 设置 > 其他 中打开日志，将选中的文件反馈给开发者。", [.ok]))
        }
    }
}

// MARK: - 添加外置登录账号页面
fileprivate struct NewYggdrasilAccountView: View {
    @ObservedObject private var state: NewAccountViewState = StateManager.shared.newAccount
    @ObservedObject private var dataManager: DataManager = .shared
    @State private var authenticationServer: String = ""
    @State private var errorMessage: String = ""
    @State private var accountIdentifier: String = ""
    @State private var password: String = ""
    
    var body: some View {
        StaticMyCard(title: "外置登录账号") {
            VStack {
                VStack {
                    HStack {
                        Text("验证服务器")
                        MyTextField(text: $authenticationServer, placeholder: "例如 https://littleskin.cn/api/yggdrasil")
                            .onChange(of: authenticationServer) {
                                if !isValidServer(authenticationServer) {
                                    errorMessage = "输入的 URL 无效！"
                                    return
                                }
                                
                                errorMessage.removeAll()
                            }
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(Color(hex: 0xFF4C4C))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack {
                        Text("账户")
                        MyTextField(text: $accountIdentifier, placeholder: "邮箱或用户名")
                    }
                    
                    HStack {
                        Text("密码")
                        MyTextField(text: $password)
                    }
                }
                .padding()
                
                HStack {
                    Spacer()
                    
                    MyButton(text: "取消") {
                        state.type = nil
                    }
                    .fixedSize()
                    
                    MyButton(text: "添加") {
                        guard isValidServer(authenticationServer) else {
                            hint("输入的 URL 无效！", .critical)
                            return
                        }
                        
                        guard !accountIdentifier.isEmpty else {
                            hint("账户不能为空！", .critical)
                            return
                        }
                        
                        guard !password.isEmpty else {
                            hint("密码不能为空！", .critical)
                            return
                        }
                        
                        Task {
                            do {
                                let account = try await YggdrasilAccount(
                                    authenticationServer: URL(string: authenticationServer)!,
                                    accountIdentifier: accountIdentifier,
                                    password: password
                                )
                                AccountManager.shared.accounts.append(.yggdrasil(account))
                                hint("添加成功！", .finish)
                                await MainActor.run {
                                    dataManager.router.removeLast()
                                    dataManager.router.append(.accountList)
                                    StateManager.shared.newAccount = .init()
                                }
                            } catch {
                                hint("登录失败：\(error.localizedDescription)", .critical)
                            }
                        }
                    }
                    .fixedSize()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: errorMessage)
            .font(.custom("PCL English", size: 14))
            .foregroundStyle(Color("TextColor"))
        }
        .noAnimation()
        .padding()
    }
    
    private func isValidServer(_ str: String) -> Bool {
        let url = URL(string: str)
        return url != nil && url!.host() != nil
    }
}

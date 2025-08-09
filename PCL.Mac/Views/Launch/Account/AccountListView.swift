//
//  AccountListView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/30.
//

import SwiftUI

struct AccountListView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject private var accountManager: AccountManager = .shared
    @ObservedObject private var settings: AppSettings = .shared
    
    var body: some View {
        ScrollView {
            VStack {
                StaticMyCard(title: "账号列表") {
                    VStack(spacing: 0) {
                        if accountManager.accounts.isEmpty {
                            Group {
                                Text("账号列表为空")
                                Text("去添加一个")
                                    .foregroundStyle(settings.theme.getTextStyle())
                                    .onTapGesture {
                                        dataManager.router.removeLast()
                                        dataManager.router.append(.newAccount)
                                    }
                            }
                            .font(.custom("PCL English", size: 14))
                            .foregroundStyle(Color("TextColor"))
                        } else {
                            ForEach(accountManager.accounts) { account in
                                AccountView(account: account)
                            }
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 25)
        }
        .scrollIndicators(.never)
        .animation(.easeInOut(duration: 0.2), value: accountManager.accounts)
    }
}

fileprivate struct AccountView: View {
    @ObservedObject private var accountManager: AccountManager = .shared
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject private var settings: AppSettings = .shared
    
    @State private var isHovered: Bool = false
    
    let account: AnyAccount
    
    var body: some View {
        MyListItem(isSelected: accountManager.accountId == account.id) {
            HStack {
                MinecraftAvatar(type: .uuid, src: account.uuid.uuidString, size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    ZStack(alignment: .leading) {
                        Text(account.name)
                            .font(.custom("PCL English", size: 14))
                            .foregroundStyle(isHovered ? settings.theme.getTextStyle() : AnyShapeStyle(Color("TextColor")))
                        
                        Text(account.uuid.uuidString.lowercased())
                            .font(.custom("PCL English", size: 12))
                            .foregroundStyle(Color(hex: 0x8C8C8C))
                            .textSelection(.enabled)
                            .offset(x: 200)
                    }
                    
                    MyTag(label: account.authMethodName, backgroundColor: Color(hex: 0x8C8C8C, alpha: 0.2))
                        .font(.custom("PCL English", size: 12))
                        .foregroundStyle(Color("TextColor"))
                }
                Spacer()
                if isHovered {
                    MyListItem {
                        Image(systemName: "xmark")
                            .bold()
                            .foregroundStyle(Color("TextColor"))
                            .padding(2)
                    }
                    .padding()
                    .onTapGesture {
                        accountManager.accounts.removeAll(where: { $0.id == account.id })
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: accountManager.accountId)
        .onHover { hover in
            isHovered = hover
        }
        .onTapGesture {
            accountManager.accountId = account.id
        }
    }
}

public extension AnyAccount {
    var authMethodName: String {
        switch self {
        case .microsoft:  return "微软账号"
        case .offline:    return "离线账号"
        case .yggdrasil:  return "外置登录"
        }
    }
}

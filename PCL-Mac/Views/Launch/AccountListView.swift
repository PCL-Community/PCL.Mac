//
//  AccountListView.swift
//  PCL-Mac
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
                StaticMyCardComponent(title: "账号列表") {
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
        MyListItemComponent(isSelected: accountManager.accountId == account.id) {
            HStack {
                MinecraftAvatarComponent(type: .username, src: account.name, size: 40)
                VStack(alignment: .leading) {
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
                    
                    let authMethodName: String = switch account {
                    case .microsoft(_): "微软"
                    case .offline(_): "离线"
                    }
                    
                    HStack {
                        MyTagComponent(label: "\(authMethodName)验证", backgroundColor: Color(hex: 0x8C8C8C, alpha: 0.2))
                            .font(.custom("PCL English", size: 12))
                            .foregroundStyle(Color("TextColor"))
                        Spacer()
                    }
                }
                Spacer()
                MyListItemComponent {
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
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hover in
            isHovered = hover
        }
        .onTapGesture {
            accountManager.accountId = account.id
        }
    }
}

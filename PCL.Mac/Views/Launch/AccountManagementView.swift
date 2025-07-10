//
//  AccountManagementView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/30.
//

import SwiftUI

struct AccountManagementView: View, SubRouteContainer {
    @ObservedObject private var dataManager: DataManager = .shared
    
    var body: some View {
        Group {
            switch dataManager.router.getLast() {
            case .accountList:
                AccountListView()
            case .newAccount:
                NewAccountView()
            default:
                Spacer()
            }
        }
        .onAppear {
            dataManager.leftTab(130) {
                VStack(alignment: .leading, spacing: 0) {
                    MyListComponent(default: .accountList, cases: [.accountList, .newAccount]) { type, isSelected in
                        createListItemView(type)
                            .foregroundStyle(isSelected ? AnyShapeStyle(AppSettings.shared.theme.getTextStyle()) : AnyShapeStyle(Color("TextColor")))
                    }
                    .id("AccountManagementList")
                    .padding(.top, 10)
                    Spacer()
                }
            }
        }
    }
    
    private func createListItemView(_ type: AppRoute) -> some View {
        var image: Image
        var text: String
        
        switch type {
        case .accountList:
            image = Image(systemName: "person.crop.circle")
            text = "账号列表"
        case .newAccount:
            image = Image(systemName: "plus.circle")
            text = "添加新账号"
        default:
            return AnyView(EmptyView())
        }
        
        return AnyView(
            HStack {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(text)
                    .font(.custom("PCL English", size: 14))
            }
        )
    }
}

fileprivate struct AccountView: View {
    @ObservedObject private var accountManager: AccountManager = .shared
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject private var settings: AppSettings = .shared
    
    @State private var isHovered: Bool = false
    
    let account: AnyAccount
    
    var body: some View {
        MyListItemComponent {
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
    }
}

//
//  SettingsView.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/5/18.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var dataManager = DataManager.shared
    
    var body: some View {
        Group {
            switch dataManager.router.getLast() {
            case .personalization:
                PersonalizationView()
            case .javaSettings:
                JavaSettingsView()
            case .otherSettings:
                OtherSettingsView()
            default:
                Spacer()
            }
        }
        .onAppear {
            dataManager.leftTab(120) {
                VStack(alignment: .leading, spacing: 0) {
                    MyListComponent(default: .personalization, cases: [.personalization, .javaSettings, .otherSettings]) { type, isSelected in
                        createListItemView(type)
                            .foregroundStyle(isSelected ? AnyShapeStyle(AppSettings.shared.theme.getTextStyle()) : AnyShapeStyle(Color("TextColor")))
                    }
                    .id("SettingsList")
                    .padding(.top, 10)
                    Spacer()
                }
            }
            
            if dataManager.javaVirtualMachines.isEmpty {
                try? JavaSearch.searchAndSet()
            }
        }
    }
    
    private func createListItemView(_ lastComponent: AppRoute) -> some View {
        switch lastComponent {
        case .personalization:
            return AnyView(
                HStack {
                    Image("PersonalizationItem")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("个性化")
                        .font(.custom("PCL English", size: 14))
                }
            )
        case .javaSettings:
            return AnyView(
                HStack {
                    Image("JavaManagerItem")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("Java 管理")
                        .font(.custom("PCL English", size: 14))
                }
            )
        case .otherSettings:
            return AnyView(
                HStack {
                    Image("InstallWaiting")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("其它")
                        .font(.custom("PCL English", size: 14))
                }
            )
        default:
            return AnyView(EmptyView())
        }
    }
}

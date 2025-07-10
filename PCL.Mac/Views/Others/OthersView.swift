//
//  OthersView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/18.
//

import SwiftUI

struct OthersView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    
    var body: some View {
        Group {
            switch dataManager.router.getLast() {
            case .about:
                AboutView()
            case .debug:
                DebugView()
            default:
                Spacer()
            }
        }
        .onAppear {
            dataManager.leftTab(140) {
                VStack(alignment: .leading, spacing: 0) {
                    MyListComponent(default: .about, cases: SharedConstants.shared.isDevelopment ? [.about, .debug] : [.about]) { type, isSelected in
                        createListItemView(type)
                            .foregroundStyle(isSelected ? AnyShapeStyle(AppSettings.shared.theme.getTextStyle()) : AnyShapeStyle(Color("TextColor")))
                    }
                    .id("OthersList")
                    .padding(.top, 10)
                    Spacer()
                }
            }
        }
    }
    
    private func createListItemView(_ lastComponent: AppRoute) -> some View {
        switch lastComponent {
        case .about:
            return AnyView(
                HStack {
                    Image("AboutItem")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("关于与鸣谢")
                        .font(.custom("PCL English", size: 14))
                }
            )
        case .debug:
            return AnyView(
                HStack {
                    Image("InstallWaiting")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("调试")
                        .font(.custom("PCL English", size: 14))
                }
            )
        default:
            return AnyView(EmptyView())
        }
    }
}

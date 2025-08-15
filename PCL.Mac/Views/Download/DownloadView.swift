//
//  DownloadView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/18.
//

import SwiftUI

struct DownloadView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    
    var body: some View {
        Group {
            switch dataManager.router.getLast() {
            case .minecraftDownload:
                MinecraftDownloadView()
            case .projectSearch(let type):
                ProjectSearchView(type: type)
                    .id(type)
            default:
                Spacer()
                    .onAppear {
                        if dataManager.router.getLast() == .download {
                            dataManager.router.append(.minecraftDownload)
                        }
                    }
            }
        }
        .onAppear {
            dataManager.leftTab(170) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Minecraft")
                        .font(.custom("PCL English", size: 12))
                        .foregroundStyle(Color(hex: 0x8C8C8C))
                        .padding(.leading, 12)
                        .padding(.top, 20)
                        .padding(.bottom, 4)
                    MyList(
                        cases: .constant([.minecraftDownload])
                    ) { type, isSelected in
                        createListItemView(type)
                            .foregroundStyle(isSelected ? AnyShapeStyle(AppSettings.shared.theme.getTextStyle()) : AnyShapeStyle(Color("TextColor")))
                    }
                    .id("DownloadList")
                    Text("社区资源")
                        .font(.custom("PCL English", size: 12))
                        .foregroundStyle(Color(hex: 0x8C8C8C))
                        .padding(.leading, 12)
                        .padding(.top, 32)
                        .padding(.bottom, 4)
                    MyList(
                        cases: .constant([.projectSearch(type: .mod), .projectSearch(type: .resourcepack)]),
                        animationIndex: 2
                    ) { type, isSelected in
                        createListItemView(type)
                            .foregroundStyle(isSelected ? AnyShapeStyle(AppSettings.shared.theme.getTextStyle()) : AnyShapeStyle(Color("TextColor")))
                    }
                    .id("DownloadList")
                    Spacer()
                }
            }
        }
    }
    
    private func createListItemView(_ lastComponent: AppRoute) -> some View {
        let imageName: String, text: String
        switch lastComponent {
        case .minecraftDownload:
            imageName = "GameDownloadIcon"
            text = "游戏下载"
        case .projectSearch(let type):
            switch type {
            case .mod:
                imageName = "ModDownloadIcon"
            case .resourcepack:
                imageName = "PictureIcon"
            case .shader:
                imageName = "ModDownloadIcon"
            }
            text = type.getName()
        default:
            return AnyView(EmptyView())
        }
        
        return AnyView(
            HStack {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(text)
                    .font(.custom("PCL English", size: 14))
            }
        )
    }
}

struct RoundedButton<Content: View>: View {
    let content: () -> Content
    let onClick: () -> Void
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    var body: some View {
        content()
            .padding()
            .background(
                RoundedRectangle(cornerRadius: .infinity)
                    .fill(AppSettings.shared.theme.getAccentColor())
            )
            .scaleEffect(isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            .onHover {
                isHovered = $0
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { value in
                        if isPressed {
                            onClick()
                        }
                        isPressed = false
                    }
            )
    }
}

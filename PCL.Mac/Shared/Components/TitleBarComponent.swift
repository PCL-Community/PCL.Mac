//
//  TitleBar.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/17.
//

import SwiftUI

struct DraggableArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DraggableHelperView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class DraggableHelperView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        self.window?.defaultButtonCell?.performClick(self)
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return self
    }
}

struct GenericTitleBarComponent<Content: View>: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack {
            ZStack {
                DraggableArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                HStack(alignment: .center) {
                    if AppSettings.shared.windowControlButtonStyle == .macOS {
                        WindowControlButton.MacOSClose
                        WindowControlButton.MacOSMiniaturize
                    }
                    content()
                    Spacer()
                    if AppSettings.shared.windowControlButtonStyle == .pcl {
                        WindowControlButton.Miniaturize
                        WindowControlButton.Close
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 48)
        .background(
            AppSettings.shared.theme.getStyle()
        )
    }
}

struct TitleBarComponent: View {
    @ObservedObject private var dataManager: DataManager = DataManager.shared
    
    var body: some View {
        GenericTitleBarComponent {
            Group {
                if AppSettings.shared.windowControlButtonStyle == .pcl {
                    Image("TitleLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 19)
                        .bold()
                    MyTagComponent(label: "Mac", backgroundColor: .white)
                        .foregroundStyle(AppSettings.shared.theme.getTextStyle())
                }
                Spacer()
                MenuItemButton(route: .launch, parent: self)
                MenuItemButton(route: .download, parent: self)
//                MenuItemButton(route: .multiplayer, parent: self)
                MenuItemButton(route: .settings, parent: self)
                MenuItemButton(route: .others, parent: self)
            }
        }
    }
}

struct SubviewTitleBarComponent: View {
    @ObservedObject private var dataManager: DataManager = DataManager.shared

    var body: some View {
        GenericTitleBarComponent {
            switch AppSettings.shared.windowControlButtonStyle {
            case .pcl:
                WindowControlButton.Back
            case .macOS:
                WindowControlButton.MacOSBack
            }
            Text(getTitle())
                .font(.custom("PCL English", size: 16))
                .foregroundStyle(.white)
        }
    }
    
    private func getTitle() -> String {
        switch dataManager.router.getLast() {
        case .installing(_): return "下载管理"
        case .versionSelect, .versionList: return "版本选择"
        case .modDownload(let summary): return "资源下载 - \(summary.name)"
        case .accountManagement, .accountList, .newAccount: return "账号管理"
        case .announcementHistory: return "历史公告"
        case .versionSettings, .instanceOverview, .instanceSettings, .instanceMods: return "版本设置 - \(AppSettings.shared.defaultInstance ?? "")"
        case .javaDownload: return "Java 下载"
        default:
            return "发现问题请在 https://github.com/PCL-Community/PCL.Mac/issues/new 上反馈！"
        }
    }
}

struct MenuItemButton: View {
    @ObservedObject private var dataManager: DataManager = DataManager.shared
    
    let route: AppRoute
    let parent: TitleBarComponent
    var icon: Image?
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13)
                .foregroundStyle(dataManager.router.getRoot() == route ? .white : (isHovered ? Color(hex: 0xFFFFFF, alpha: 0.17) : .clear))
            
            HStack {
                getImage()
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(dataManager.router.getRoot() == route ?
                                     AnyShapeStyle(AppSettings.shared.theme.getTextStyle()) : AnyShapeStyle(.white))
                Text(getText())
                    .foregroundStyle(dataManager.router.getRoot() == route ?
                                     AnyShapeStyle(AppSettings.shared.theme.getTextStyle()) : AnyShapeStyle(.white))
            }
        }
        .frame(width: 75, height: 27)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: dataManager.router.getRoot() == route)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if dataManager.router.getRoot() != route {
                        dataManager.router.setRoot(route)
                    }
                }
        )
        .onHover { hover in
            isHovered = hover
        }
    }
    
    private func getImage() -> Image {
        let key = switch route {
        case .launch: "LaunchIcon"
        case .download: "DownloadIcon"
        case .multiplayer: "MultiplayerIcon"
        case .settings: "SettingsIcon"
        case .others: "OthersIcon"
        default: ""
        }
        return Image(key)
    }
    
    private func getText() -> String {
        return switch route {
        case .launch: "启动"
        case .download: "下载"
        case .multiplayer: "联机"
        case .settings: "设置"
        case .others: "更多"
        default: ""
        }
    }
}

#Preview {
    TitleBarComponent()
}

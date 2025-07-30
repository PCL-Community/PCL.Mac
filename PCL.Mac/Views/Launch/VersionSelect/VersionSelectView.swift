//
//  VersionSelectView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/12.
//

import SwiftUI
import UniformTypeIdentifiers

struct VersionSelectView: View, SubRouteContainer {
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject private var settings: AppSettings = .shared
    
    @State private var directoryRoutes: [AppRoute] = AppSettings.shared.minecraftDirectories.map { .versionList(directory: $0) }
    
    var body: some View {
        Group {
            switch dataManager.router.getLast() {
            case .versionList(let directory):
                VersionListView(minecraftDirectory: directory)
            default:
                Spacer()
                    .onAppear {
                        if let directory = settings.currentMinecraftDirectory {
                            dataManager.router.append(.versionList(directory: directory))
                        }
                    }
            }
        }
        .onAppear {
            dataManager.leftTab(300) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("文件夹列表")
                        .font(.custom("PCL English", size: 12))
                        .foregroundStyle(Color(hex: 0x8C8C8C))
                        .padding(.leading, 12)
                        .padding(.top, 20)
                        .padding(.bottom, 4)
                    MyListComponent(
                        cases: $directoryRoutes,
                        height: 42,
                        content: { type, isSelected in
                            createListItemView(type)
                                .foregroundStyle(isSelected ? AnyShapeStyle(settings.theme.getTextStyle()) : AnyShapeStyle(Color("TextColor")))
                        }
                    )
                    Text("添加或导入")
                        .font(.custom("PCL English", size: 12))
                        .foregroundStyle(Color(hex: 0x8C8C8C))
                        .padding(.leading, 12)
                        .padding(.top, 20)
                        .padding(.bottom, 4)
                    LeftTabItem(imageName: "PlusIcon", text: "添加已有文件夹")
                        .onTapGesture {
                            let panel = NSOpenPanel()
                            panel.allowsMultipleSelection = false
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.allowedContentTypes = [.folder]
                            
                            if panel.runModal() == .OK {
                                guard !settings.minecraftDirectories.contains(where: { $0.rootUrl == panel.url! }) else {
                                    hint("该目录已存在！", .critical)
                                    return
                                }
                                settings.minecraftDirectories.append(.init(rootUrl: panel.url!, name: "自定义目录"))
                                settings.currentMinecraftDirectory = .init(rootUrl: panel.url!, name: "自定义目录")
                                hint("添加成功", .finish)
                            }
                        }
                    Spacer()
                }
            }
        }
        .onDrop(of: [.folder], delegate: VersionDropDelegate())
        .onChange(of: settings.minecraftDirectories) { new in
            directoryRoutes = new.map { .versionList(directory: $0) }
        }
    }
    
    private func createListItemView(_ type: AppRoute) -> some View {
        if case .versionList(let directory) = type {
            return AnyView(
                HStack {
                    VStack(alignment: .leading) {
                        Text(directory.name)
                            .font(.custom("PCL English", size: 14))
                            .foregroundStyle(.primary)
                        Text(directory.rootUrl.path)
                            .font(.custom("PCL English", size: 12))
                            .foregroundStyle(Color(hex: 0x8C8C8C))
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "trash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16)
                        .foregroundStyle(Color("TextColor"))
                        .onTapGesture {
                            settings.removeDirectory(url: directory.rootUrl)
                            hint("移除成功", .finish)
                        }
                        .padding(4)
                }
            )
        }
        return AnyView(EmptyView())
    }
}

fileprivate struct LeftTabItem: View {
    let imageName: String
    let text: String
    
    var body: some View {
        MyListItemComponent {
            HStack {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24)
                    .foregroundStyle(Color("TextColor"))
                    .padding(.leading)
                    .padding(.top, 6)
                    .padding(.bottom, 6)
                Text(text)
                    .font(.custom("PCL English", size: 14))
                    .foregroundStyle(Color("TextColor"))
                Spacer()
            }
        }
        
    }
}

#Preview {
    VersionSelectView()
}

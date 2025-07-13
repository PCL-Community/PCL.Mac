//
//  DownloadPage.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/8.
//

import SwiftUI

struct DownloadPage: View {
    let version: MinecraftVersion
    let back: () -> Void
    
    @State private var name: String
    @State private var tasks: InstallTasks = .empty()
    
    init(_ version: MinecraftVersion, _ back: @escaping () -> Void) {
        self.version = version
        self.name = version.displayName
        self.back = back
        self.tasks.addTask(key: "minecraft", task: MinecraftInstaller.createTask(version, version.displayName, AppSettings.shared.currentMinecraftDirectory!))
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                TitlelessMyCardComponent(hasAnimation: false) {
                    HStack(alignment: .center) {
                        Image("Back")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15)
                            .foregroundStyle(Color(hex: 0x96989A))
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                            .onTapGesture {
                                back()
                            }
                        Image(version.getIconName())
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35)
                        MyTextFieldComponent(text: self.$name)
                            .foregroundStyle(Color("TextColor"))
                    }
                }
                .padding()
                FabricLoaderCard(tasks: $tasks, version: version)
                    .padding()
                    .padding(.top, 20)
                Spacer()
            }
            .scrollIndicators(.never)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    RoundedButton {
                        HStack {
                            Image("DownloadIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20)
                            Text("开始下载")
                                .font(.custom("PCL English", size: 16))
                        }
                    } onClick: {
                        guard NetworkTest.shared.hasNetworkConnection() else {
                            ContentView.setPopup(PopupOverlay("无互联网连接", "请确保当前设备已联网！", [.Ok]))
                            warn("试图下载新版本，但无网络连接")
                            return
                        }
                        
                        if DataManager.shared.inprogressInstallTasks != nil { return }
                        
                        if let task = tasks.tasks["minecraft"] as? MinecraftInstallTask {
                            task.name = self.name
                            task.onComplete {
                                DispatchQueue.main.async {
                                    HintManager.default.add(.init(text: "\(name) 下载完成！", type: .finish))
                                    AppSettings.shared.defaultInstance = name
                                    DataManager.shared.router.removeLast()
                                }
                            }
                        }
                        
                        DataManager.shared.inprogressInstallTasks = self.tasks
                        DataManager.shared.router.append(.installing(tasks: tasks))
                        self.tasks.tasks["minecraft"]!.start()
                    }
                    .foregroundStyle(.white)
                    .padding()
                    Spacer()
                }
            }
        }
    }
}

fileprivate struct FabricLoaderCard: View {
    @State private var versions: [FabricManifest]? = nil
    @State private var height: CGFloat = .zero
    @State private var showText: Bool = true
    @State private var selected: FabricManifest? = nil
    @Binding private var tasks: InstallTasks
    
    let version: MinecraftVersion
    
    init(tasks: Binding<InstallTasks>, version: MinecraftVersion) {
        self._tasks = tasks
        self.version = version
    }
    
    var body: some View {
        ZStack {
            Group {
                if let versions = versions, !versions.isEmpty {
                    MyCardComponent(index: 1, hasAnimation: false, title: "Fabric") {
                        LazyVStack(spacing: 0) {
                            ForEach(versions) { version in
                                ListItem(iconName: "Fabric", title: version.loaderVersion, description: version.stable ? "稳定版" : "测试版", isSelected: selected?.loaderVersion == version.loaderVersion)
                                    .animation(.easeInOut(duration: 0.2), value: selected?.id)
                                    .onTapGesture {
                                        selected = version
                                        tasks.addTask(key: "fabric", task: FabricInstallTask(loaderVersion: selected!.loaderVersion))
                                    }
                            }
                        }
                    }
                    .onToggle { isUnfolded in
                        showText = !isUnfolded
                    }
                } else {
                    TitlelessMyCardComponent(index: 1, hasAnimation: false) {
                        HStack {
                            MaskedTextRectangle(text: "Fabric")
                            Spacer()
                        }
                        .frame(height: 9)
                    }
                }
            }
            
            if showText {
                HStack {
                    Group {
                        if let selected = selected {
                            Image("Fabric")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16)
                            Text(selected.loaderVersion)
                        } else {
                            Text(text)
                        }
                    }
                    .font(.custom("PCL English", size: 14))
                    .foregroundStyle(Color(hex: 0x8C8C8C))
                    .offset(x: 150, y: 14)
                    
                    Spacer()
                }
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            loadVersions()
        }
    }
    
    private var text: String {
        if versions == nil {
            return "加载中……"
        }
        
        if versions!.isEmpty {
            return "无可用版本"
        }
        
        return "可以添加"
    }
    
    private func loadVersions() {
        Task {
            if let data = await Requests.get(
                "https://meta.fabricmc.net/v2/versions/loader/\(version.displayName)"
            ).data,
               let manifests = try? FabricManifest.parse(data) {
                DispatchQueue.main.async {
                    versions = manifests
                }
            }
        }
    }
    
    private struct ListItem: View {
        let iconName: String
        let title: String
        let description: String
        let isSelected: Bool
        
        init(iconName: String, title: String, description: String, isSelected: Bool) {
            self.iconName = iconName
            self.title = title
            self.description = description
            self.isSelected = isSelected
        }
        
        var body: some View {
            MyListItemComponent(isSelected: isSelected) {
                HStack {
                    Image(iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35)
                        .padding(.leading, 5)
                    VStack(alignment: .leading) {
                        Text(title)
                            .foregroundStyle(Color("TextColor"))
                        Text(description)
                            .foregroundStyle(Color(hex: 0x8C8C8C))
                    }
                    .font(.custom("PCL English", size: 14))
                    Spacer()
                }
                .padding(4)
            }
        }
    }
}

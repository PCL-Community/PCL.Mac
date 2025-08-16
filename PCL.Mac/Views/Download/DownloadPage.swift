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
    @State private var errorMessage: String = ""
    
    init(_ version: MinecraftVersion, _ back: @escaping () -> Void) {
        self.version = version
        self.name = version.displayName
        self.back = back
        self.tasks.addTask(key: "minecraft", task: MinecraftInstaller.createTask(version, version.displayName, AppSettings.shared.currentMinecraftDirectory!))
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                TitlelessMyCard {
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
                        VStack {
                            MyTextField(text: $name)
                                .foregroundStyle(Color("TextColor"))
                                .onChange(of: name) {
                                    if name == version.displayName && tasks.tasks.count > 1 {
                                        errorMessage = "带 Mod 加载器的实例名不能与版本号一致！"
                                    } else if name.isEmpty {
                                        errorMessage = "实例名不能为空！"
                                    } else {
                                        errorMessage = ""
                                    }
                                }
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundStyle(Color(hex: 0xFF4C4C))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: errorMessage)
                    }
                }
                .noAnimation()
                .padding()
                
                LoaderCard(tasks: $tasks, name: $name, version: version, loader: .fabric)
                    .padding()
                    .padding(.top, 20)
                
                LoaderCard(tasks: $tasks, name: $name, version: version, loader: .forge)
                    .padding()
                
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
                        guard errorMessage.isEmpty else {
                            hint(errorMessage, .critical)
                            return
                        }
                        
                        guard NetworkTest.shared.hasNetworkConnection() else {
                            PopupManager.shared.show(.init(.error, "无互联网连接", "请确保当前设备已联网！", [.ok]))
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

private struct LoaderVersion: Identifiable, Equatable {
    let id: UUID = .init()
    let loader: ClientBrand
    let version: String
    let stable: Bool
    
    static func == (lhs: LoaderVersion, rhs: LoaderVersion) -> Bool {
        lhs.version == rhs.version && lhs.loader == rhs.loader
    }
}

fileprivate struct LoaderCard: View {
    @State private var versions: [LoaderVersion]? = nil
    @State private var height: CGFloat = .zero
    @State private var showText: Bool = true
    @State private var selected: LoaderVersion? = nil
    @State private var isUnfolded: Bool = false
    @State private var isSelected: Bool = false
    @Binding private var tasks: InstallTasks
    @Binding private var name: String
    private let loader: ClientBrand
    
    let version: MinecraftVersion
    
    init(tasks: Binding<InstallTasks>, name: Binding<String>, version: MinecraftVersion, loader: ClientBrand) {
        self._tasks = tasks
        self._name = name.wrappedValue == version.displayName ? name : .constant(name.wrappedValue)
        self.version = version
        self.loader = loader
    }
    
    var body: some View {
        ZStack {
            Group {
                if let versions = versions, !versions.isEmpty, !isSelected {
                    MyCard(index: 1, title: loader.getName(), unfoldBinding: $isUnfolded) {
                        LazyVStack(spacing: 0) {
                            ForEach(versions) { version in
                                ListItem(iconName: "\(loader.rawValue.capitalized)Icon", title: version.version, description: version.stable ? "稳定版" : "测试版", isSelected: selected == version)
                                    .animation(.easeInOut(duration: 0.2), value: selected?.id)
                                    .onTapGesture {
                                        selected = version
                                        let taskConstructor: ((String) -> InstallTask)? =
                                        switch loader {
                                        case .fabric: FabricInstallTask.init(loaderVersion:)
                                        case .forge: ForgeInstallTask.init(forgeVersion:)
                                        default: nil
                                        }
                                        
                                        if let taskConstructor {
                                            tasks.addTask(key: loader.rawValue, task: taskConstructor(version.version))
                                        }
                                        isUnfolded = false
                                        name.append("-\(loader.getName()) \(version.version)")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                            isSelected = true
                                        }
                                    }
                            }
                        }
                    }
                    .noAnimation()
                    .onToggle { isUnfolded in
                        showText = !isUnfolded
                    }
                } else {
                    TitlelessMyCard(index: 1) {
                        HStack {
                            MaskedTextRectangle(text: loader.getName())
                            Spacer()
                            if isSelected {
                                Image(systemName: "xmark")
                                    .resizable()
                                    .scaledToFit()
                                    .bold()
                                    .frame(width: 16)
                                    .foregroundStyle(Color("TextColor"))
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        isSelected = false
                                        selected = nil
                                        tasks.tasks.removeValue(forKey: loader.rawValue)
                                        name = version.displayName
                                    }
                            }
                        }
                        .frame(height: 9)
                    }
                    .noAnimation()
                }
            }
            
            if showText {
                HStack {
                    Group {
                        if let selected = selected {
                            Image("\(loader.rawValue.capitalized)Icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16)
                            Text(selected.version)
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
        .task {
            await loadVersions()
        }
    }
    
    private var text: String {
        if versions == nil { return "加载中……" }
        if versions!.isEmpty { return "无可用版本" }
        if let selected { return selected.version }
        
        return "可以添加"
    }
    
    private func loadVersions() async {
        switch loader {
        case .fabric:
            if let json = await Requests.get("https://meta.fabricmc.net/v2/versions/loader/\(version.displayName)").json {
                versions = json.arrayValue.map { LoaderVersion(loader: .fabric, version: $0["loader"]["version"].stringValue, stable: $0["loader"]["stable"].boolValue) }
            }
        case .forge:
            if let json = await Requests.get("https://bmclapi2.bangbang93.com/forge/minecraft/\(version.displayName)").json {
                versions = json.arrayValue.map { LoaderVersion(loader: .forge, version: $0["version"].stringValue, stable: true) }
            }
        default:
            versions = []
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
            MyListItem(isSelected: isSelected) {
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

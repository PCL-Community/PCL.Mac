//
//  VersionSettingsView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/16.
//

import SwiftUI
import ZIPFoundation
import SwiftyJSON

struct VersionSettingsView: View, SubRouteContainer {
    @ObservedObject private var dataManager: DataManager = .shared
    
    private let instance: MinecraftInstance!
    
    init() {
        if let directory = AppSettings.shared.currentMinecraftDirectory,
           let defaultInstance = AppSettings.shared.defaultInstance,
           let instance = MinecraftInstance.create(directory, directory.versionsUrl.appending(path: defaultInstance)) {
            self.instance = instance
        } else {
            self.instance = nil
        }
    }
    
    var body: some View {
        Group {
            switch dataManager.router.getLast() {
            case .instanceOverview:
                InstanceOverviewView(instance: instance)
            case .instanceSettings:
                InstanceSettingsView(instance: instance)
            default:
                InstanceModsView(instance: instance)
            }
        }
        .onAppear {
            dataManager.leftTab(200) {
                VStack(alignment: .leading, spacing: 0) {
                    MyListComponent(
                        root: .versionSettings(instance: instance),
                        cases: .constant(
                            [
                                .instanceOverview,
                                .instanceSettings,
                                .instanceMods
                            ]
                        )) { route, isSelected in
                            createListItemView(route)
                                .foregroundStyle(isSelected ? AnyShapeStyle(AppSettings.shared.theme.getTextStyle()) : AnyShapeStyle(Color("TextColor")))
                        }
                        .padding(.top, 10)
                    Spacer()
                }
            }
        }
    }
    
    private func createListItemView(_ route: AppRoute) -> some View {
        let imageName: String
        let text: String
        
        switch route {
        case .instanceOverview:
            imageName = "GameDownloadIcon"
            text = "概览"
        case .instanceSettings:
            imageName = "SettingsIcon"
            text = "设置"
        case .instanceMods:
            imageName = "ModDownloadIcon"
            text = "Mod"
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

struct InstanceOverviewView: View {
    let instance: MinecraftInstance
    
    var body: some View {
        ScrollView {
            TitlelessMyCardComponent {
                HStack {
                    Image(instance.getIconName())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32)
                    VStack(alignment: .leading) {
                        Text(instance.config.name)
                        Text(getVersionString())
                            .foregroundStyle(Color(hex: 0x8C8C8C))
                    }
                    .font(.custom("PCL English", size: 14))
                    .foregroundStyle(Color("TextColor"))
                    Spacer()
                }
            }
            .padding()
        }
        .scrollIndicators(.never)
    }
    
    private func getVersionString() -> String {
        var str = instance.version.displayName
        if instance.clientBrand != .vanilla {
            str += ", \(instance.clientBrand.getName())"
        }
        
        return str
    }
}

struct InstanceSettingsView: View {
    @State var instance: MinecraftInstance
    @State private var memoryText: String
    
    let qosOptions: [QualityOfService] = [
        .userInteractive,
        .userInitiated,
        .default,
        .utility,
        .background
    ]
    
    init(instance: MinecraftInstance) {
        self.instance = instance
        self.memoryText = String(instance.config.maxMemory)
    }
    
    var body: some View {
        ScrollView {
            StaticMyCardComponent(title: "进程设置") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("游戏内存")
                        MyTextFieldComponent(text: $memoryText, numberOnly: true)
                            .onChange(of: memoryText) { new in
                                if let intValue = Int(new) {
                                    instance.config.maxMemory = Int32(intValue)
                                    instance.saveConfig()
                                }
                            }
                        Text("MB")
                    }
                    VStack(spacing: 2) {
                        HStack {
                            Text("进程 QoS")
                            MyPickerComponent(selected: $instance.config.qualityOfService, entries: qosOptions, textProvider: getQualityOfServiceName(_:))
                            .onChange(of: instance.config.qualityOfService) { _ in
                                instance.saveConfig()
                            }
                        }
                        
                        Text("​QoS 是控制进程 CPU 优先级的属性，可调整多任务下的资源分配，保障游戏进程优先运行，推荐默认。")
                            .font(.custom("PCL English", size: 12))
                            .foregroundStyle(Color(hex: 0x8C8C8C))
                            .padding(.top, 2)
                    }
                }
                .padding()
            }
            .padding()
        }
        .font(.custom("PCL English", size: 14))
        .scrollIndicators(.never)
    }
    
    private func getQualityOfServiceName(_ qos: QualityOfService) -> String {
        switch qos {
        case .userInteractive:
            "用户交互 (最高优先级)"
        case .userInitiated:
            "用户启动 (高优先级)"
        case .utility:
            "实用工具 (低优先级)"
        case .background:
            "后台 (最低优先级)"
        case .default:
            "默认"
        @unknown default:
            "未知"
        }
    }
}

struct InstanceModsView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @State private var searchQuery: String = ""
    @State private var mods: [Mod]? = nil
    @State private var error: Error?
    
    private let taskID: UUID = .init()
    let instance: MinecraftInstance
    
    var body: some View {
        if instance.clientBrand == .vanilla {
            VStack {
                TitlelessMyCardComponent {
                    VStack {
                        Text("该实例不可使用 Mod")
                            .font(.custom("PCL English", size: 22))
                            .foregroundStyle(AppSettings.shared.theme.getTextStyle())
                        Rectangle()
                            .fill(AppSettings.shared.theme.getTextStyle())
                            .frame(height: 2)
                        VStack(alignment: .leading) {
                            Text("你需要先安装 Forge、Fabric 等 Mod 加载器才能使用 Mod，请在下载页面安装这些实例。")
                            Text("如果你已经安装过了 Mod 加载器，那么你很可能选择了错误的实例，请点击实例选择按钮切换实例。")
                        }
                        .font(.custom("PCL English", size: 14))
                        .foregroundStyle(Color("TextColor"))
                        .padding(4)
                        
                        HStack(spacing: 24) {
                            MyButtonComponent(text: "转到下载页面", foregroundStyle: AppSettings.shared.theme.getTextStyle()) {
                                dataManager.router.setRoot(.download)
                                dataManager.router.append(.minecraftDownload)
                            }
                            .frame(width: 170, height: 40)
                            
                            MyButtonComponent(text: "实例选择") {
                                dataManager.router.setRoot(.versionSelect)
                            }
                            .frame(width: 170, height: 40)
                        }
                    }
                    .padding(4)
                }
                .padding(40)
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollView {
                MyTipComponent(text: "目前只支持 Fabric Mod 识别！", color: .blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                
                MySearchBox(query: $searchQuery, placeholder: "搜索资源 名称 / 描述 / 标签", onSubmit: { _ in })
                    .padding()
                    .padding(.top, -25)
                
                TitlelessMyCardComponent(index: 1) {
                    HStack(spacing: 16) {
                        MyButtonComponent(text: "打开文件夹", foregroundStyle: AppSettings.shared.theme.getTextStyle()) {
                            NSWorkspace.shared.open(instance.runningDirectory.appending(path: "mods"))
                        }
                        .frame(width: 120, height: 35)
                        MyButtonComponent(text: "下载新资源") {
                            dataManager.router.setRoot(.download)
                            dataManager.router.append(.modSearch)
                        }
                        .frame(width: 120, height: 35)
                        Spacer()
                    }
                    .padding(2)
                }
                .padding()
                
                if let mods = mods {
                    TitlelessMyCardComponent(index: 2) {
                        VStack(spacing: 0) {
                            ForEach(mods) { mod in
                                ModView(mod: mod)
                            }
                            if mods.isEmpty {
                                Text("你还没有安装任何模组！")
                                    .font(.custom("PCL English", size: 14))
                                    .foregroundStyle(Color("TextColor"))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    Text("加载中……")
                        .font(.custom("PCL English", size: 14))
                        .foregroundStyle(Color("TextColor"))
                }
                
                Spacer()
            }
            .scrollIndicators(.never)
            .task(id: taskID) {
                if mods != nil || instance.clientBrand == .vanilla { return }
                do {
                    var mods: [Mod] = []
                    let loader = instance.clientBrand
                    let files = try FileManager.default.contentsOfDirectory(at: instance.runningDirectory.appending(path: "mods"), includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                    let jarFiles = files.filter { $0.pathExtension.lowercased() == "jar" }
                    for jarFile in jarFiles {
                        do {
                            let archive = try Archive(url: jarFile, accessMode: .read)
                            var mod: Mod? = nil
                            if loader == .fabric {
                                mod = .fromFabricJSON(try JSON(data: ZipUtil.getEntryOrThrow(archive: archive, name: "fabric.mod.json")))
                            }
                            
                            if let mod = mod {
                                mods.append(mod)
                                loadSummary(mod: mod)
                            }
                        } catch {}
                    }
                    await MainActor.run {
                        self.mods = mods
                    }
                } catch {
                    self.error = error
                }
            }
        }
    }
    
    private func loadSummary(mod: Mod) {
        Task {
            if let summary = try? await ModSearcher.shared.get(mod.id) { // 若 slug 与 Mod ID 一致，使用通过 Mod ID 获取到的 Project
                await MainActor.run {
                    mod.summary = summary
                }
            } else { // 否则搜索最匹配的 Mod
                if let summary = try? await ModSearcher.shared.search(
                    query: mod.name,
                    version: instance.version,
                    loader: instance.clientBrand,
                    limit: 1
                ).first {
                    await MainActor.run {
                        mod.summary = summary
                    }
                } else {
                    warn("未找到 \(mod.id) 对应的 Modrinth Project")
                }
            }
        }
    }
    
    struct ModView: View {
        @ObservedObject private var dataManager: DataManager = .shared
        @ObservedObject private var mod: Mod
        @ObservedObject private var state: ModSearchViewState = StateManager.shared.modSearch
        @State private var isHovered: Bool = false
        
        init(mod: Mod) {
            self.mod = mod
        }
        
        var body: some View {
            MyListItemComponent {
                HStack(alignment: .center) {
                    getIconImage()
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 0) {
                            Text(mod.summary?.name ?? mod.name)
                                .font(.custom("PCL English", size: 14))
                                .foregroundStyle(Color("TextColor"))
                            Text(" | \(mod.version)")
                                .foregroundStyle(Color(hex: 0x8C8C8C))
                        }
                        HStack {
                            ForEach((mod.summary?.tags ?? []).compactMap { ModListItem.tagMap[$0] }, id: \.self) { tag in
                                MyTagComponent(label: tag, backgroundColor: Color("TagColor"), fontSize: 12)
                            }
                            
                            Text(mod.summary?.description ?? mod.description)
                                .font(.custom("PCL English", size: 14))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .foregroundStyle(Color(hex: 0x8C8C8C))
                    }
                    .font(.custom("PCL English", size: 12))
                    Spacer()
                    
                    if let summary = mod.summary, isHovered {
                        Image("InfoIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16)
                            .foregroundStyle(AppSettings.shared.theme.getTextStyle())
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dataManager.router.append(.modDownload(summary: summary))
                            }
                    }
                }
                .padding(4)
            }
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { isHovered in
                self.isHovered = isHovered
            }
        }
        
        /// 获取未经任何处理的模组图标 Image
        private func getIconImage() -> Image {
            if let summary = mod.summary {
                if let icon = state.iconCache[summary.projectId] {
                    return icon
                } else {
                    Task {
                        if let url = summary.iconUrl,
                           let data = await Requests.get(url).data,
                           let nsImage = NSImage(data: data) {
                            DispatchQueue.main.async {
                                self.state.iconCache[summary.projectId] = Image(nsImage: nsImage)
                            }
                        }
                    }
                    return Image("ModIconPlaceholder")
                }
            }
            
            // TODO: 读取 Mod 图标
            return Image("ModIconPlaceholder")
        }
    }
}

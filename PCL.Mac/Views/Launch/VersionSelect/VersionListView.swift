//
//  VersionList.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/1.
//

import SwiftUI

struct VersionListView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    let minecraftDirectory: MinecraftDirectory
    
    struct VersionView: View, Identifiable {
        let name: String
        let description: String
        let instance: MinecraftInstance
        
        let id: UUID = UUID()
        
        init(instance: MinecraftInstance) {
            self.name = instance.config.name
            self.description = instance.version.displayName
            self.instance = instance
        }
        
        var body: some View {
            MyListItemComponent {
                HStack {
                    Image(self.instance.getIconName())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35)
                        .padding(.leading, 5)
                    VStack(alignment: .leading) {
                        Text(self.name)
                            .font(.custom("PCL English", size: 14))
                            .foregroundStyle(Color("TextColor"))
                            .padding(.top, 5)
                        Text(self.description)
                            .font(.custom("PCL English", size: 14))
                            .foregroundStyle(Color(hex: 0x7F8790))
                            .padding(.bottom, 5)
                    }
                    Spacer()
                }
            }
            .onTapGesture {
                AppSettings.shared.defaultInstance = instance.config.name
                DataManager.shared.router.setRoot(.launch)
            }
            .padding(.top, -8)
        }
    }
    var body: some View {
        VStack {
            if minecraftDirectory.instances.isEmpty {
                ZStack {
                    Spacer()
                        .frame(maxWidth: .infinity)
                    Text("加载中……")
                        .foregroundStyle(Color("TextColor"))
                        .font(.custom("PCL English", size: 14))
                }
            } else {
                ScrollView {
                    let notVanillaVersions = minecraftDirectory.instances.filter { $0.clientBrand != .vanilla }
                    if !notVanillaVersions.isEmpty {
                        MyCardComponent(index: 0, title: "可安装 Mod") {
                            LazyVStack {
                                ForEach(
                                    notVanillaVersions
                                        .sorted(by: { $0.version! > $1.version! })
                                        .sorted(by: { $0.clientBrand.index < $1.clientBrand.index })
                                ) { instance in
                                    VersionView(instance: instance)
                                }
                            }
                            .padding(.top, 12)
                        }
                        .padding()
                    }
                    MyCardComponent(index: 1, title: "常规版本") {
                        LazyVStack {
                            ForEach(
                                minecraftDirectory.instances
                                    .filter { $0.clientBrand == .vanilla }
                                    .sorted(by: { $0.version! > $1.version! })
                            ) { instance in
                                VersionView(instance: instance)
                            }
                        }
                        .padding(.top, 12)
                    }
                    .padding()
                    .padding(.bottom, 25)
                }
                .scrollIndicators(.never)
            }
        }
        .id(minecraftDirectory)
        .onChange(of: minecraftDirectory, perform: loadInstances)
        .onAppear { loadInstances(minecraftDirectory) }
    }
    
    private func loadInstances(_ directory: MinecraftDirectory) {
        AppSettings.shared.currentMinecraftDirectory = directory
        if directory.instances.isEmpty {
            directory.loadInnerInstances()
        }
    }
}


class VersionDropDelegate: DropDelegate {
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.folder])
    }
    
    func performDrop(info: DropInfo) -> Bool {
        let providers = info.itemProviders(for: [.folder])
        for provider in providers {
            provider.loadItem(forTypeIdentifier: provider.registeredTypeIdentifiers[0], options: nil) { item, error in
                if let error = error {
                    err(error.localizedDescription)
                }
                
                if let url = item as? URL, url.hasDirectoryPath {
                    guard FileManager.default.fileExists(atPath: url.appending(path: "\(url.lastPathComponent).json").path) else {
                        hint("请拖入正确的 Minecraft 版本文件夹！", .critical)
                        return
                    }
                    
                    hint("正在导入实例 \(url.lastPathComponent)……")
                    Task {
                        let dest = URL(fileURLWithUserPath: "~/PCL-Mac-minecraft/versions/\(url.lastPathComponent)")
                        if FileManager.default.fileExists(atPath: dest.path) {
                            hint("已存在同名实例！", .critical)
                            return
                        }
                        do {
                            try FileManager.default.copyItem(at: url, to: dest)
                            AppSettings.shared.defaultInstance = url.lastPathComponent
                            hint("导入成功！", .finish)
                        } catch {
                            err("无法复制实例: \(error.localizedDescription)")
                            hint("无法复制实例: \(error.localizedDescription)", .critical)
                        }
                    }
                }
            }
            return true
        }
        return false
    }
}

//
//  MinecraftDownloadView.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/6/20.
//

import SwiftUI

fileprivate struct VersionView: View, Identifiable {
    let name: String
    let description: String
    let icon: String
    let parent: MinecraftDownloadView
    let version: VersionManifest.GameVersion
    
    let id: UUID = UUID()
    
    init(version: VersionManifest.GameVersion, isLatest: Bool = false, parent: MinecraftDownloadView) {
        self.name = version.id
        
        var description = SharedConstants.shared.dateFormatter.string(from: version.releaseTime)
        if isLatest {
            description = "最新\(version.type == "release" ? "正式" : "预览")版，发布于 " + description
        }
        self.description = description
        
        self.icon = version.parse().getIconName()
        self.parent = parent
        self.version = version
    }
    
    var body: some View {
        MyListItemComponent {
            HStack {
                Image(self.icon)
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
        .padding(.top, -8)
        .onTapGesture {
            self.parent.onVersionClicked(version)
        }
    }
}

struct MinecraftDownloadView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    
    @State private var versions: [String: [VersionManifest.GameVersion]]? = nil
    @State private var currentDownloadPage: DownloadPage?
    
    var body: some View {
        HStack {
            if let currentDownloadPage = self.currentDownloadPage {
                currentDownloadPage
                    .zIndex(0)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack {
                        if let manifest = dataManager.versionManifest {
                            StaticMyCardComponent(index: 0, title: "最新版本") {
                                VStack {
                                    VersionView(version: manifest.getLatestRelease(), isLatest: true, parent: self)
                                    VersionView(version: manifest.getLatestSnapshot(), isLatest: true, parent: self)
                                }
                                .padding(.top, 12)
                            }
                            .padding()
                        }
                        
                        if let versions = self.versions {
                            CategoryCard(index: 1, label: "正式版", versions: versions["release"]!, parent: self)
                            CategoryCard(index: 2, label: "预览版", versions: versions["snapshot"]!, parent: self)
                            CategoryCard(index: 3, label: "远古版", versions: versions["old"]!, parent: self)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
                .zIndex(0)
                .transition(.move(edge: .leading).combined(with: .opacity))
                .scrollIndicators(.never)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentDownloadPage == nil)
        .onAppear {
            var versions: [String: [VersionManifest.GameVersion]] = [:]
            versions["release"] = dataManager.versionManifest!.versions.filter { $0.type == "release" }
            versions["snapshot"] = dataManager.versionManifest!.versions.filter { $0.type == "snapshot" }
            versions["old"] = dataManager.versionManifest!.versions.filter { $0.type == "old_beta" || $0.type == "old_alpha" }
            self.versions = versions
        }
    }
    
    func onVersionClicked(_ version: VersionManifest.GameVersion) {
        let version = version.parse()
        self.currentDownloadPage = DownloadPage(version) {
            self.currentDownloadPage = nil
        }
    }
}

fileprivate struct CategoryCard: View {
    let index: Int
    let label: String
    let versions: [VersionManifest.GameVersion]
    let parent: MinecraftDownloadView
    
    var body: some View {
        MyCardComponent(index: index, title: "\(label) (\(versions.count))") {
            LazyVStack {
                ForEach(versions, id: \.self) { version in
                    VersionView(version: version, parent: parent)
                }
            }
            .padding(.top, 12)
        }
        .padding()
    }
}

fileprivate struct DownloadPage: View {
    let version: MinecraftVersion
    let back: () -> Void
    
    @State private var name: String
    
    @ObservedObject private var currentTask: Holder<InstallTask> = Holder()
    
    init(_ version: MinecraftVersion, _ back: @escaping () -> Void) {
        self.version = version
        self.name = version.displayName
        self.back = back
    }
    
    var body: some View {
        ZStack {
            VStack {
                TitlelessMyCardComponent {
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
                            .frame(height: 12)
                            .foregroundStyle(Color("TextColor"))
                    }
                }
                .padding()
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    RoundedButton {
                        HStack {
                            Image("DownloadItem")
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
                        
                        if DataManager.shared.inprogressInstallTask != nil { return }
                        self.currentTask.setObject(MinecraftInstaller.createTask(version, name, MinecraftDirectory(rootUrl: URL(fileURLWithUserPath: "~/PCL-Mac-minecraft"))) {
                            DispatchQueue.main.async {
                                HintManager.default.add(.init(text: "\(name) 下载完成！", type: .finish))
                                AppSettings.shared.defaultInstance = name
                                DataManager.shared.router.removeLast()
                                DataManager.shared.inprogressInstallTask = nil
                            }
                        })
                        DataManager.shared.inprogressInstallTask = self.currentTask.object!
                        DataManager.shared.router.append(.installing(task: self.currentTask.object!))
                        self.currentTask.object!.start()
                    }
                    .foregroundStyle(.white)
                    .padding()
                    Spacer()
                }
            }
        }
    }
}

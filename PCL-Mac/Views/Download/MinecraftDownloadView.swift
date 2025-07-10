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
                            CategoryCard(index: 4, label: "愚人节版", versions: versions["april_fool"]!, parent: self)
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
            versions["april_fool"] = dataManager.versionManifest!.versions.filter { $0.type == "april_fool" }
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

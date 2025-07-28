//
//  ModDownloadView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/20.
//

import SwiftUI

// 别问为什么抽出来，问就是 The compiler is unable to type-check this expression in reasonable time; try breaking up the expression into distinct sub-expressions
fileprivate struct ModVersionListView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject var summary: ModSummary
    @State private var requestID = UUID()
    @State private var versionMap: ModVersionMap = [:]
    
    let versions: [String]
    
    var body: some View {
        VStack {
            ForEach(sortedReleaseVersions, id: \.self) { version in
                ForEach(summary.loaders, id: \.self) { loader in
                    if let versions: [ModVersion] = versionMap[ModPlatformKey(loader: loader, minecraftVersion: version)] {
                        MyCardComponent(title: "\(loader.getName()) \(version.displayName)") {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                if let version = versions.first,
                                   !version.dependencies.isEmpty {
                                    Text("前置资源")
                                        .font(.custom("PCL English", size: 14))
                                        .padding(4)
                                    ForEach(version.dependencies, id: \.self) { dependency in
                                        ModListItem(summary: dependency.summary)
                                            .onTapGesture {
                                                dataManager.router.append(.modDownload(summary: dependency.summary))
                                            }
                                    }
                                    Text("版本列表")
                                        .font(.custom("PCL English", size: 14))
                                        .padding(4)
                                }
                                ForEach(versions) { version in
                                    ModVersionListItem(version: version)
                                    .onTapGesture {
                                        if let instance = dataManager.defaultInstance {
                                            let task = ModInstallTask(instance: instance, version: version)
                                            dataManager.inprogressInstallTasks = .single(task)
                                            task.start()
//                                            ContentView.setPopup(PopupOverlay("URL", version.downloadURL.absoluteString, [.Ok]))
                                        }
                                    }
                                }
                            }
                            .padding(4)
                        }
                        .padding()
                    }
                }
            }
        }
        .task(id: requestID) {
            if let map = try? await ModSearcher.shared.getVersionMap(id: summary.modId) {
                DispatchQueue.main.async {
                    self.versionMap = map
                }
            }
        }
    }
    
    private var sortedReleaseVersions: [MinecraftVersion] {
        summary.gameVersions
            .filter { $0.type == .release }
            .sorted(by: >)
    }
}

fileprivate struct ModVersionListItem: View {
    let version: ModVersion
    
    var body: some View {
        MyListItemComponent {
            HStack {
                Image(version.type.capitalized + "Icon")
                    .resizable()
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading) {
                    Text(version.name)
                        .font(.custom("PCL English", size: 14))
                    Text(getDescription())
                        .font(.custom("PCL English", size: 14))
                        .foregroundStyle(Color(hex: 0x8C8C8C))
                }
                Spacer()
            }
            .padding(4)
        }
    }
    
    private func getDescription() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .full
        let result = formatter.localizedString(for: version.updateDate, relativeTo: Date()).replacingOccurrences(of: "(\\d+)", with: " $1 ", options: .regularExpression)
        let typeText = switch version.type {
        case "release":
            "正式版"
        case "beta", "alpha":
            "测试版"
        default:
            "未知"
        }
        return "\(version.versionNumber)，更新于\(result)，\(typeText)"
    }
}

struct ModDownloadView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @State private var summary: ModSummary?
    let id: String
    
    init(id: String) {
        self.id = id
    }
    
    var body: some View {
        Group {
            if let summary = summary {
                ScrollView {
                    TitlelessMyCardComponent {
                        VStack {
                            ModListItem(summary: summary)
                            HStack(spacing: 25) {
                                MyButtonComponent(text: "转到 Modrinth", foregroundStyle: AppSettings.shared.theme.getTextStyle()) {
                                    NSWorkspace.shared.open(summary.infoUrl)
                                }
                                .frame(width: 160, height: 40)
                                
                                MyButtonComponent(text: "复制名称") {
                                    NSPasteboard.general.setString(summary.name, forType: .string)
                                }
                                .frame(width: 160, height: 40)
                                Spacer()
                            }
                        }
                        .padding(10)
                    }
                    .padding()
                    if let versions = summary.versions {
                        ModVersionListView(summary: summary, versions: versions)
                    }
                }
                .scrollIndicators(.never)
            } else {
                Spacer()
            }
        }
        .id(id)
        .onAppear {
            dataManager.leftTab(0) { EmptyView() }
        }
        .task(id: id) {
            summary = nil
            summary = try? await ModSearcher.shared.get(id)
        }
    }
}


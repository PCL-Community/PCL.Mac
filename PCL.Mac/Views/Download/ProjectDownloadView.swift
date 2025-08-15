//
//  ProjectDownloadView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/20.
//

import SwiftUI

// 别问为什么抽出来，问就是 The compiler is unable to type-check this expression in reasonable time; try breaking up the expression into distinct sub-expressions
fileprivate struct ProjectVersionListView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject private var state: ProjectSearchViewState = StateManager.shared.projectSearch
    @State private var requestID = UUID()
    @State private var versionMap: ProjectVersionMap = [:]
    
    let summary: ProjectSummary
    let versions: [String]
    
    var body: some View {
        VStack {
            ForEach(versionMap.gameVersions, id: \.self) { version in
                ForEach(versionMap.loaders, id: \.self) { loader in
                    if let versions: [ProjectVersion] = versionMap[ProjectPlatformKey(loader: loader, minecraftVersion: version)] {
                        MyCard(title: "\(loader.getName()) \(version.displayName)") {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                if let version = versions.first,
                                   !version.dependencies.isEmpty {
                                    Text("前置资源")
                                        .font(.custom("PCL English", size: 14))
                                        .padding(4)
                                    ForEach(version.dependencies, id: \.self) { dependency in
                                        ProjectListItem(summary: dependency.summary)
                                            .onTapGesture {
                                                dataManager.router.append(.projectDownload(summary: dependency.summary))
                                            }
                                    }
                                    Text("版本列表")
                                        .font(.custom("PCL English", size: 14))
                                        .padding(4)
                                }
                                ForEach(versions) { version in
                                    ProjectVersionListItem(version: version)
                                    .onTapGesture {
                                        state.addToQueue(version)
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
            do {
                let map = try await ModrinthProjectSearcher.shared.getVersionMap(id: summary.modId)
                DispatchQueue.main.async {
                    self.versionMap = map
                }
            } catch {
                err("无法加载版本列表: \(error.localizedDescription)")
            }
        }
    }
}

fileprivate struct ProjectVersionListItem: View {
    let version: ProjectVersion
    
    var body: some View {
        MyListItem {
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

struct ProjectDownloadView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject private var state: ProjectSearchViewState = StateManager.shared.projectSearch
    @State private var summary: ProjectSummary?
    let id: String
    
    init(id: String) {
        self.id = id
    }
    
    var body: some View {
        Group {
            if let summary = summary {
                ScrollView {
                    TitlelessMyCard {
                        VStack {
                            ProjectListItem(summary: summary)
                            HStack(spacing: 25) {
                                MyButton(text: "转到 Modrinth", foregroundStyle: AppSettings.shared.theme.getTextStyle()) {
                                    NSWorkspace.shared.open(summary.infoURL)
                                }
                                .frame(width: 160, height: 40)
                                
                                MyButton(text: "复制名称") {
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
                        ProjectVersionListView(summary: summary, versions: versions)
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
            summary = try? await ModrinthProjectSearcher.shared.get(id)
        }
    }
}


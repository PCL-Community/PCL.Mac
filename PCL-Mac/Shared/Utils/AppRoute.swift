//
//  AppRoute.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/5/29.
//

import SwiftUI

public enum AppRoute: Hashable {
    // 根页面
    case launch
    case download
    case multiplayer
    case settings
    case others
    
    // 子页面
    case accountManagement
    case accountList
    case newAccount
    case installing(tasks: InstallTasks)
    case versionList
    case modDownload(summary: ModSummary)
    case announcementHistory
    
    // MyList 导航
    case minecraftDownload
    case modSearch
    
    case about
    case debug
    
    case personalization
    case javaSettings
    case otherSettings
    
    var isRoot: Bool {
        switch self {
        case .launch, .download, .multiplayer, .settings, .others,
                .minecraftDownload, .modSearch,
                .about, .debug,
                .personalization, .javaSettings, .otherSettings:
            return true
        default:
            return false
        }
    }
    
    var name: String {
        switch self {
        case .installing(let task): "installing?task=\(task.id)"
        case .modDownload(let summary): "modDownload?summary=\(summary.id)"
        default:
            String(describing: self)
        }
    }
}

public class AppRouter: ObservableObject {
    @Published public private(set) var path: [AppRoute] = [.launch]
    
    public func append(_ route: AppRoute) {
        path.append(route)
    }
    
    public func getLastView() -> any View {
        switch getLast() {
        case .launch:
            LaunchView()
        case .accountManagement, .accountList, .newAccount:
            AccountManagementView()
        case .download, .minecraftDownload, .modSearch:
            DownloadView()
        case .multiplayer:
            MultiplayerView()
        case .settings, .personalization, .javaSettings, .otherSettings:
            SettingsView()
        case .others, .about, .debug:
            OthersView()
        case .installing(let tasks):
            InstallingView(tasks: tasks)
        case .versionList:
            VersionListView()
        case .modDownload(let summary):
            ModDownloadView(summary: summary)
        case .announcementHistory:
            AnnouncementHistoryView()
        }
    }
    
    public func getDebugText() -> String {
        return "/" + path.map { $0.name }.joined(separator: "/")
    }
    
    public func removeLast() {
        self.path.removeLast()
        if self.path.isEmpty {
            self.path.append(.launch)
        }
    }
    
    public func setRoot(_ root: AppRoute) {
        path.removeAll()
        path.append(root)
    }
    
    public func getLast() -> AppRoute {
        return path.last!
    }
    
    public func getRoot() -> AppRoute {
        return path.first!
    }
}

/// 若该视图为子页面，且有子路由，需要实现此协议以便正常返回。
protocol SubRouteContainer { }

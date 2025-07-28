//
//  AppRoute.swift
//  PCL.Mac
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
    case versionSelect
    case modDownload(summary: NewModSummary)
    case announcementHistory
    case versionSettings(instance: MinecraftInstance)
    
    // MyList 导航
    case minecraftDownload
    case modSearch
    case versionList(directory: MinecraftDirectory)
    case instanceOverview
    case instanceSettings
    case instanceMods
    
    case about
    case toolbox
    case debug
    
    case personalization
    case javaSettings
    case otherSettings
    
    var isRoot: Bool {
        switch self {
        case .launch, .download, .multiplayer, .settings, .others,
                .minecraftDownload, .modSearch,
                .about, .toolbox, .debug,
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
        case .versionList(let directory): "versionList?rootUrl=\(directory.rootUrl.path)"
        case .versionSettings(let instance): "versionSettings?instance=\(instance.config.name)"
        default:
            String(describing: self)
        }
    }
    
    func isSame(_ another: AppRoute) -> Bool {
        if case .versionList(let directory1) = self,
           case .versionList(let directory2) = another {
            return directory1.rootUrl == directory2.rootUrl
        }
        
        return self == another
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
        case .others, .about, .toolbox, .debug:
            OthersView()
        case .installing(let tasks):
            InstallingView(tasks: tasks)
        case .versionSelect, .versionList(_):
            VersionSelectView()
        case .modDownload(let summary):
            ModDownloadView(id: summary.modId)
        case .announcementHistory:
            AnnouncementHistoryView()
        case .versionSettings, .instanceOverview, .instanceSettings, .instanceMods:
            VersionSettingsView()
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

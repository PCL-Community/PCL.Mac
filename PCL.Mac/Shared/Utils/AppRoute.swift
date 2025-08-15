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
    case projectDownload(summary: ProjectSummary)
    case announcementHistory
    case versionSettings(instance: MinecraftInstance)
    
    // MyList 导航
    case minecraftDownload
    case projectSearch(type: ProjectType)
    case versionList(directory: MinecraftDirectory)
    case instanceOverview
    case instanceSettings
    case instanceMods
    case javaDownload
    
    case about
    case toolbox
    case debug
    
    case personalization
    case javaSettings
    case otherSettings
    case themeUnlock
    
    var isRoot: Bool {
        switch self {
        case .launch, .download, .multiplayer, .settings, .others,
                .minecraftDownload, .projectSearch(_),
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
        case .projectDownload(let summary): "projectDownload?summary=\(summary.modId)"
        case .versionList(let directory): "versionList?rootURL=\(directory.rootURL.path)"
        case .versionSettings(let instance): "versionSettings?instance=\(instance.config.name)"
        case .projectSearch(let type): "projectSearch?type=\(type)"
        default:
            String(describing: self)
        }
    }
    
    var title: String {
        switch self {
        case .installing(_): "下载管理"
        case .versionSelect, .versionList: "版本选择"
        case .projectDownload(let summary): "资源下载 - \(summary.name)"
        case .accountManagement, .accountList, .newAccount: "账号管理"
        case .announcementHistory: "历史公告"
        case .versionSettings, .instanceOverview, .instanceSettings, .instanceMods: "版本设置 - \(AppSettings.shared.defaultInstance ?? "")"
        case .javaDownload: "Java 下载"
        case .themeUnlock: "主题解锁"
        default: "发现问题请在 https://github.com/PCL-Community/PCL.Mac/issues/new 上反馈！"
        }
    }
    
    func isSame(_ another: AppRoute) -> Bool {
        if case .versionList(let directory1) = self,
           case .versionList(let directory2) = another {
            return directory1.rootURL == directory2.rootURL
        }
        
        return self == another
    }
}

public class AppRouter: ObservableObject {
    @Published public var path: [AppRoute] = [.launch]
    
    public func append(_ route: AppRoute) {
        path.append(route)
    }
    
    public func getLastView() -> any View {
        switch getLast() {
        case .launch:
            LaunchView()
        case .accountManagement, .accountList, .newAccount:
            AccountManagementView()
        case .download, .minecraftDownload, .projectSearch(_):
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
        case .projectDownload(let summary):
            ProjectDownloadView(id: summary.modId)
        case .announcementHistory:
            AnnouncementHistoryView()
        case .versionSettings, .instanceOverview, .instanceSettings, .instanceMods:
            VersionSettingsView()
        case .javaDownload:
            JavaInstallView()
        case .themeUnlock:
            ThemeUnlockView()
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
protocol SubRouteContainer {
    func shouldPop() -> Bool
}

extension SubRouteContainer {
    func shouldPop() -> Bool { true }
}

//
//  LocalStorage.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/19.
//

import SwiftUI

public enum ColorSchemeOption: Codable {
    case light, dark, system
    func getLabel() -> String {
        switch self {
        case .light:
            "浅色模式"
        case .dark:
            "深色模式"
        case .system:
            "跟随系统"
        }
    }
}

public enum WindowControlButtonStyle: Codable {
    case pcl, macOS
    func getLabel() -> String {
        switch self {
        case .pcl:
            "PCL"
        case .macOS:
            "macOS"
        }
    }
}

public enum DownloadSourceOption: Codable {
    case official, mirror, both
}

public class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    /// 是否显示 PCL.Mac 弹窗
    @AppStorage("showPclMacPopup") public var showPclMacPopup: Bool = true
    
    /// 用户添加的 Java 路径
    @CodableAppStorage("userAddedJvmPaths") public var userAddedJvmPaths: [URL] = []
    
    @Published public var theme: Theme!
    
    /// 主题 ID (文件名)
    @CodableAppStorage("themeId") public var themeId: String = "pcl" {
        didSet {
            if themeId != self.theme.id {
                self.theme = .load(id: themeId)
                DataManager.shared.objectWillChange.send()
            }
        }
    }
    
    /// 启动时若为空自动设置为第一个版本
    @AppStorage("defaultInstance") public var defaultInstance: String?
    
    /// 配色方案
    @CodableAppStorage("colorScheme") public var colorScheme: ColorSchemeOption = .light
    
    /// 最后一次获取到的 VersionManifest，断网时使用
    @CodableAppStorage("lastVersionManifest") public var lastVersionManifest: VersionManifest? = nil
    
    /// 当前 MinecraftDirectory
    @CodableAppStorage("currentMinecraftDirectory") public var currentMinecraftDirectory: MinecraftDirectory? = .default
    
    /// 所有 MinecraftDirectory
    @CodableAppStorage("minecraftDirectories") public var minecraftDirectories: [MinecraftDirectory] = [.default]
    
    /// 窗口按钮样式
    @CodableAppStorage("windowControlButtonStyle") public var windowControlButtonStyle: WindowControlButtonStyle = .pcl
    
    /// 是否登录过一次微软账号
    @AppStorage("hasMicrosoftAccount") public var hasMicrosoftAccount: Bool = false
    
    /// 累计启动次数
    @AppStorage("launchCount") public var launchCount: Int = 0
    
    /// 启动器是否全屏
    @AppStorage("fullScreen") public var fullScreen: Bool = false
    
    /// 下载自定义文件时的保存 URL
    @AppStorage("customFilesSaveURL") public var customFilesSaveURL: URL = URL(fileURLWithUserPath: "~/Downloads")
    
    /// 使用过的主题解锁码
    @CodableAppStorage("usedThemeCodes") public var usedThemeCodes: [String] = []
    
    /// 是否启用超薄材质
    @CodableAppStorage("useUltraThinMaterial") public var useUltraThinMaterial: Bool = false
    
    /// 文件下载源
    @CodableAppStorage("fileDownloadSource") public var fileDownloadSource: DownloadSourceOption = .both
    
    /// 版本列表源
    @CodableAppStorage("versionManifestSource") public var versionManifestSource: DownloadSourceOption = .both
    
    public func updateColorScheme() {
        if colorScheme != .system {
            NSApp.appearance = colorScheme == .light ? NSAppearance(named: .aqua) : NSAppearance(named: .darkAqua)
        } else {
            NSApp.appearance = nil
        }
        ColorConstants.colorScheme = colorScheme
        self.theme = .load(id: themeId)
        DataManager.shared.objectWillChange.send()
    }
    
    private init() {
        updateColorScheme()
        
        if currentMinecraftDirectory == nil {
            currentMinecraftDirectory = .default
        }
        
        if let directory = currentMinecraftDirectory {
            if !minecraftDirectories.contains(where: { $0.rootURL == directory.rootURL }) {
                minecraftDirectories.append(directory)
            }
            
            if defaultInstance == nil {
                directory.loadInnerInstances { instances in
                    self.defaultInstance = instances.first?.name
                }
            }
        }
        log("已加载启动器设置")
    }
    
    public func removeDirectory(url: URL) {
        if currentMinecraftDirectory?.rootURL == url || currentMinecraftDirectory == nil {
            currentMinecraftDirectory = .default
            if case .versionList = DataManager.shared.router.getLast() {
                DataManager.shared.router.removeLast()
                DataManager.shared.router.append(.versionList(directory: .default))
            }
        }
        minecraftDirectories.removeAll(where: { $0.rootURL == url })
        
        if minecraftDirectories.isEmpty {
            minecraftDirectories.append(currentMinecraftDirectory!)
        }
        
        DataManager.shared.objectWillChange.send()
    }
}

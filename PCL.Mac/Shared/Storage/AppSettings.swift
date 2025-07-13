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

public class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    /// 是否显示 PCL.Mac 弹窗
    @AppStorage("showPclMacPopup") public var showPclMacPopup: Bool = true
    
    /// 用户添加的 Java 路径
    @CodableAppStorage("userAddedJvmPaths") public var userAddedJvmPaths: [URL] = []
    
    /// 主题需要观察 DataManager 才能更新
    @CodableAppStorage("theme") public var theme: Theme = .pcl

    /// 是否使用彩色背景（对应PCL的UiBackgroundColorful）
    @AppStorage("backgroundColorful") public var backgroundColorful: Bool = true

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

    /// 是否启用Beta UI效果
    @AppStorage("enableBetaUI") public var enableBetaUI: Bool = false

    /// 是否登录过一次微软账号
    @AppStorage("hasMicrosoftAccount") public var hasMicrosoftAccount: Bool = false
    
    /// 累计启动次数
    @AppStorage("launchCount") public var launchCount: Int = 0
    
    public func updateColorScheme() {
        if colorScheme != .system {
            NSApp.appearance = colorScheme == .light ? NSAppearance(named: .aqua) : NSAppearance(named: .darkAqua)
        } else {
            NSApp.appearance = .currentDrawing()
        }
    }
    
    private init() {
        log("已加载持久化储存数据")
        updateColorScheme()
        
        if currentMinecraftDirectory == nil {
            currentMinecraftDirectory = .default
        }
        
        if let directory = currentMinecraftDirectory {
            if !minecraftDirectories.contains(where: { $0.rootUrl == directory.rootUrl }) {
                minecraftDirectories.append(directory)
            }
            
            // 判断 defaultInstance 是否合法
            if let defaultInstance = defaultInstance,
               MinecraftInstance.create(runningDirectory: directory.versionsUrl.appending(path: defaultInstance)) == nil {
                warn("无效的 defaultInstance 配置")
                self.defaultInstance = nil
            }
            
            if defaultInstance == nil {
                directory.loadInnerInstances(callback: { self.defaultInstance = $0.first?.config.name })
            }
        }
    }
    
    public func removeDirectory(url: URL) {
        if currentMinecraftDirectory?.rootUrl == url || currentMinecraftDirectory == nil {
            currentMinecraftDirectory = .default
            if case .versionList = DataManager.shared.router.getLast() {
                DataManager.shared.router.removeLast()
                DataManager.shared.router.append(.versionList(directory: .default))
            }
        }
        minecraftDirectories.removeAll(where: { $0.rootUrl == url })
        
        if minecraftDirectories.isEmpty {
            minecraftDirectories.append(currentMinecraftDirectory!)
        }
        
        DataManager.shared.objectWillChange.send()
    }
}

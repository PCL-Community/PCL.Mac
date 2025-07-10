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

public class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    /// 是否显示 PCL.Mac 弹窗
    @AppStorage("showPclMacPopup") public var showPclMacPopup: Bool = true
    
    /// 用户添加的 Java 路径
    @CodableAppStorage(wrappedValue: [], "userAddedJvmPaths") public var userAddedJvmPaths: [URL]
    
    /// 主题需要观察 DataManager 才能更新
    @CodableAppStorage(wrappedValue: .pcl, "theme") public var theme: Theme
    
    /// 启动时若为空自动设置为第一个版本
    @AppStorage("defaultInstance") public var defaultInstance: String?
    
    /// 配色方案
    @CodableAppStorage(wrappedValue: ColorSchemeOption.light, "colorScheme") public var colorScheme: ColorSchemeOption
    
    /// 最后一次获取到的 VersionManifest，断网时使用
    @CodableAppStorage(wrappedValue: nil, "lastVersionManifest") public var lastVersionManifest: VersionManifest?
    
    public func updateColorScheme() {
        if colorScheme != .system {
            NSApp.appearance = colorScheme == .light ? NSAppearance(named: .aqua) : NSAppearance(named: .darkAqua)
        }
    }
    
    private init() {
        log("已加载持久化储存数据")
    }
}

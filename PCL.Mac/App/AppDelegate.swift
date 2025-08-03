//
//  AppDelegate.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/19.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: 注册字体
    private func registerCustomFonts() {
        guard let fontURL = Bundle.main.url(forResource: "PCL", withExtension: "ttf") else {
            err("Bundle 内未找到字体")
            return
        }

        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) == false {
            if let error = error?.takeUnretainedValue() {
                err("无法注册字体: \(error.localizedDescription)")
            } else {
                err("在注册字体时发生未知错误")
            }
        } else {
            log("成功注册字体")
        }
    }
    
    // MARK: 初始化 Java 列表
    private func initJavaList() {
        do {
            try JavaSearch.searchAndSet()
        } catch {
            err("无法初始化 Java 列表: \(error.localizedDescription)")
        }
    }
    
    // MARK: 初始化 App
    func applicationWillFinishLaunching(_ notification: Notification) {
        LogStore.shared.clear()
        let start = Date().timeIntervalSince1970
        log("App 已启动")
        _ = AppSettings.shared
        registerCustomFonts()
        DataManager.shared.refreshVersionManifest()
        
        log("正在初始化 Java 列表")
        initJavaList()
        log("App 初始化完成, 耗时 \(Int((Date().timeIntervalSince1970 - start) * 1000))ms")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if AppSettings.shared.showPclMacPopup {
            ContentView.setPopup(
                PopupOverlay(
                    "欢迎使用 PCL.Mac！",
                    "若要反馈问题，请到 QQ 群 1047463389，或直接在 GitHub 上开 Issue，而不是去 CE 群！",
                    [.init(text: "永久关闭") { AppSettings.shared.showPclMacPopup = false ; PopupButton.Close.onClick() }, .Ok]
                )
            )
        }
        Aria2Manager.shared.checkAndDownloadAria2()
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        LogStore.shared.save()
        Task {
            await Aria2Manager.shared.shutdown()
            NSApplication.shared.terminate(sender)
        }
        return .terminateLater
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

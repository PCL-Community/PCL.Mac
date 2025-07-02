//
//  PCL_MacApp.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/5/17.
//

import SwiftUI

@main
struct PCL_MacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        _ = AppStartTracker.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(WindowAccessor())
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 PCL-Mac") {
                    DataManager.shared.router.setRoot(.others)
                    DataManager.shared.router.append(.about)
                }
            }
            
            CommandGroup(replacing: .appSettings) {
                Button("设置") {
                    DataManager.shared.router.setRoot(.settings)
                    DataManager.shared.router.append(.personalization)
                }
            }
            
            CommandGroup(replacing: .newItem) { } // 修复 #21
        }
        .windowStyle(.hiddenTitleBar) // 避免刚启动时闪一下标题栏
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let nsView = NSView()
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.setContentSize(NSSize(width: 815, height: 465))
                window.isOpaque = false
                window.backgroundColor = NSColor.clear
                window.styleMask = [.borderless, .miniaturizable]
                
                if let contentView = window.contentView {
                    contentView.wantsLayer = true
                    contentView.layer?.cornerRadius = 10
                    contentView.layer?.masksToBounds = true
                }
            }
        }
        return nsView
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

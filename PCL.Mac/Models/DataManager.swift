//
//  DataManager.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/19.
//

import SwiftUI
import Combine

/// 需要在界面上同步 / 使用的都放在这里
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var javaVirtualMachines: [JavaVirtualMachine] = []
    @Published var lastTimeUsed: Int = 0
    @Published var currentPopup: PopupOverlay?
    @Published var popupState: PopupAnimationState = .beforePop
    @Published var networkMonitor: NetworkSpeedMonitor = NetworkSpeedMonitor()
    @Published var versionManifest: VersionManifest?
    @Published var router: AppRouter = .init()
    @Published var leftTabWidth: CGFloat = 310
    @Published var leftTabContent: AnyView = AnyView(EmptyView())
    @Published var leftTabId: UUID = .init()
    @Published var downloadSpeed: Double = 0
    @Published var inprogressInstallTasks: InstallTasks?
    var defaultInstance: MinecraftInstance? {
        if let directory = AppSettings.shared.currentMinecraftDirectory,
           let defaultInstance = AppSettings.shared.defaultInstance,
           let instance = MinecraftInstance.create(directory, defaultInstance) {
            return instance
        }
        return nil
    }
    
    private var routerCancellable: AnyCancellable?
    
    private init() {
        routerCancellable = router.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
    
    func refreshVersionManifest() {
        versionManifest = AppSettings.shared.lastVersionManifest
        if NetworkTest.shared.hasNetworkConnection() {
            Task {
                if let versionManifest = await VersionManifest.getVersionManifest() {
                    await MainActor.run {
                        self.versionManifest = versionManifest
                        AppSettings.shared.lastVersionManifest = self.versionManifest
                        log("版本清单获取成功")
                    }
                } else {
                    warn("在获取版本清单时发生错误，使用最后一次获取到的版本清单")
                }
            }
        } else {
            if AppSettings.shared.lastVersionManifest != nil {
                warn("无网络连接，使用最后一次获取到的版本清单")
            } else {
                err("无网络连接，但最后一次获取到的版本清单也为空，程序被迫终止")
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    func leftTab(_ width: CGFloat, _ content: @escaping () -> some View) {
        DispatchQueue.main.async {
            self.leftTabWidth = width
            self.leftTabContent = AnyView(content())
            self.leftTabId = .init()
        }
    }
}

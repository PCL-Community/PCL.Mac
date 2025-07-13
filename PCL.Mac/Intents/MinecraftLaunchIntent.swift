//
//  TestIndent.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/3.
//

import AppIntents
import Foundation

struct MinecraftLaunchIntent: AppIntent {
    static var title: LocalizedStringResource = "启动 Minecraft"
    static var description: IntentDescription = IntentDescription("启动指定的 Minecraft 实例")
    
    @Parameter(title: "实例名")
    var instanceName: String
    
    @Parameter(title: "跳过资源完整性校验")
    var skipResourceCheck: Bool

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let before: DispatchTime = .now()
        guard let directory = AppSettings.shared.currentMinecraftDirectory else {
            return .result(dialog: "未设置默认 Minecraft 目录。")
        }
        
        let instance = MinecraftInstance.create(runningDirectory: directory.versionsUrl.appending(path: instanceName))
        guard let instance = instance else {
            return .result(dialog: .init("实例不存在。"))
        }
        let options = LaunchOptions()
        options.skipResourceCheck = true
        
        Task {
            await instance.launch(options)
        }
        
        return .result(dialog: .init("在 \((DispatchTime.now().uptimeNanoseconds - before.uptimeNanoseconds) / 1_000_000)ms 内成功创建进程。"))
    }
}

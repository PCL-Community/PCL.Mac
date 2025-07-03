//
//  TestIndent.swift
//  PCL-Mac
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

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let instance = MinecraftInstance.create(runningDirectory: URL(fileURLWithUserPath: "~/PCL-Mac-minecraft/versions").appending(path: instanceName))
        guard let instance = instance else {
            return .result(dialog: .init("错误：实例不存在"))
        }
        Task {
            await instance.launch(skipResourceCheck: true)
        }
        return .result(dialog: .init("启动成功"))
    }
}

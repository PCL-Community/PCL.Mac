//
//  MinecraftCrashHandler.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/14.
//

import Foundation
import ZIPFoundation

public class MinecraftCrashHandler {
    public static var lastLaunchCommand: String = "未设置"
    
    
    public static func exportErrorReport(_ instance: MinecraftInstance, _ launcher: MinecraftLauncher, to destination: URL) {
        log("以下是 PCL.Mac 检测到的环境信息:")
        log("架构: \(Architectury.system)")
        log("分支: \(SharedConstants.shared.branch)")
        log("Java 架构: \(Architectury.getArchOfFile(URL(fileURLWithPath: instance.config.javaPath!)))")
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: instance.runningDirectory.appending(path: "natives"),
                includingPropertiesForKeys: nil
            )
            for fileURL in contents {
                if fileURL.pathExtension != "dylib" { continue }
                log("\(fileURL.lastPathComponent) 架构: \(Architectury.getArchOfFile(fileURL))")
            }
        } catch {
            err("无法获取本地库: \(error.localizedDescription)")
        }
        
        debug("正在导出错误报告")
        let tmp = SharedConstants.shared.temperatureUrl.appending(path: "ErrorReport")
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        
        FileManager.default.createFile(atPath: tmp.appending(path: "启动命令.command").path, contents: lastLaunchCommand.data(using: .utf8))
        try? FileManager.default.copyItem(at: SharedConstants.shared.logUrl, to: tmp.appending(path: "PCL.Mac 启动器日志.txt"))
        try? FileManager.default.copyItem(at: launcher.logUrl, to: tmp.appending(path: "游戏崩溃前的输出.txt"))
        try? FileManager.default.copyItem(at: instance.runningDirectory.appending(path: instance.config.name + ".json"), to: tmp.appending(path: instance.config.name + ".json"))
        try? FileManager.default.zipItem(at: tmp, to: destination, shouldKeepParent: false)
        debug("错误报告导出完成")
        try? FileManager.default.removeItem(at: launcher.logUrl)
        Util.clearTemp()
    }
}

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
        // MARK: - 输出环境信息
        log("以下是 PCL.Mac 检测到的环境信息:")
        log("架构: \(Architecture.system)")
        log("分支: \(SharedConstants.shared.branch)")
        log("Java 架构: \(Architecture.getArchOfFile(instance.config.javaURL!))")
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: instance.runningDirectory.appending(path: "natives"),
                includingPropertiesForKeys: nil
            )
            for fileURL in contents {
                if fileURL.pathExtension != "dylib" { continue }
                log("\(fileURL.lastPathComponent) 架构: \(Architecture.getArchOfFile(fileURL))")
            }
        } catch {
            err("无法获取本地库: \(error.localizedDescription)")
        }
        
        debug("正在导出错误报告")
        
        let tmp = TemperatureDirectory(name: "ErrorReport")
        try? FileManager.default.createDirectory(at: tmp.root, withIntermediateDirectories: true)
        
        // 导出启动命令
        tmp.createFile(path: "启动命令.command", data: lastLaunchCommand.data(using: .utf8))
        
        // 导出日志与输出
        try? FileManager.default.copyItem(at: SharedConstants.shared.logURL, to: tmp.root.appending(path: "PCL.Mac 启动器日志.log"))
        try? FileManager.default.copyItem(at: launcher.logURL, to: tmp.root.appending(path: "游戏崩溃前的输出.txt"))
        copyGameLogs(instance: instance, report: tmp.root)
        
        try? FileManager.default.copyItem(at: instance.runningDirectory.appending(path: instance.name + ".json"), to: tmp.root.appending(path: instance.name + ".json"))
        try? FileManager.default.zipItem(at: tmp.root, to: destination, shouldKeepParent: false)
        debug("错误报告导出完成")
        try? FileManager.default.removeItem(at: launcher.logURL)
        Util.clearTemp()
    }
    
    private static func copyGameLogs(instance: MinecraftInstance, report: URL) {
        let logsURL = instance.runningDirectory.appending(path: "logs")
        try? FileManager.default.copyItem(at: logsURL.appending(path: "latest.log"), to: report.appending(path: "latest.log"))
        try? FileManager.default.copyItem(at: logsURL.appending(path: "debug.log"), to: report.appending(path: "debug.log"))
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: instance.runningDirectory.appending(path: "crash-reports"), includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            
            let latestReport = files
                .filter { $0.hasDirectoryPath == false }
                .max(by: {
                    let date0 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                    let date1 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                    return date0 < date1
                })
            
            if let latestFile = latestReport {
                try FileManager.default.copyItem(at: latestFile, to: report.appending(path: latestFile.lastPathComponent))
            }
        } catch {
            err("无法复制 crash-report: \(error.localizedDescription)")
        }
    }
}

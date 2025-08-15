//
//  ModLoaderInstaller.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/17.
//

/**
 *                             _ooOoo_
 *                            o8888888o
 *                            88" . "88
 *                            (| -_- |)
 *                            O\  =  /O
 *                         ____/`---'\____
 *                       .'  \\|     |//  `.
 *                      /  \\|||  :  |||//  \
 *                     /  _||||| -:- |||||-  \
 *                     |   | \\\  -  /// |   |
 *                     | \_|  ''\---/''  |   |
 *                     \  .-\__  `-`  ___/-. /
 *                   ___`. .'  /--.--\  `. . __
 *                ."" '<  `.___\_<|>_/___.'  >'"".
 *               | | :  `- \`.;`\ _ /`;.`/ - ` : | |
 *               \  \ `-.   \_ __\ /__ _/   .-` /  /
 *          ======`-.____`-.___\_____/___.-`____.-'======
 *                             `=---='
 *          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*/

import Foundation
import ZIPFoundation

public class ModLoaderInstaller {
    public static func installNeoforge(_ instance: MinecraftInstance, _ version: String) async {
            if instance.clientBrand != .vanilla {
                err("无法安装 NeoForge: 实例 \(instance.config.name) 已有 Mod 加载器: \(instance.clientBrand.rawValue)")
                return
            }
        if let data = await Requests.get(
            "https://bmclapi2.bangbang93.com/neoforge/list/\(instance.version!.displayName)"
        ).data,
            let manifests = try? NeoforgeManifest.parse(data) {
            guard let manifest = manifests.find({ $0.version == version }) else {
                err("找不到对应的 Neoforge 版本: \(version)")
                return
            }
            
            let temp = SharedConstants.shared.temperatureURL.appending(path: "neoforge_install")
            let installer = temp.appending(path: "installer.jar")
            
            // 1. 下载安装器
            await withCheckedContinuation { continuation in
                let downloader = ProgressiveDownloader(
                    urls: [manifest.installerURL],
                    destinations: [installer],
                    completion: continuation.resume
                )
                downloader.start()
            }
            
            // 2. 解压安装器
            do {
                try FileManager.default.unzipItem(at: installer, to: temp)
            } catch {
                err("无法解压安装器: \(error.localizedDescription)")
                return
            }
            
            // 3. 解析 install_profile.json
            let profile: NeoforgeInstallProfile
            do {
                let handle = try FileHandle(forReadingFrom: temp.appending(path: "install_profile.json"))
                profile = try NeoforgeInstallProfile(.init(data: try handle.readToEnd()!))
            } catch {
                err("无法解析 install_profile.json: \(error.localizedDescription)")
                return
            }
            
            // 4. 安装所需依赖
            await withCheckedContinuation { continuation in
                let downloader = ProgressiveDownloader(
                    urls: profile.libraries.map { $0.downloadURL },
                    destinations: profile.libraries.map { temp.appending(path: $0.path) },
                    skipIfExists: true,
                    completion: continuation.resume
                )
                downloader.start()
            }
            
            // 5. 准备环境变量
            var values = profile.data.mapValues { path in
                let parse = parse(path, in: instance.minecraftDirectory)
                if parse == path {
                    return temp.appending(path: parse).path
                }
                return parse
            }
            
            values = values.merging(
                [
                    "SIDE": "client",
                    "MINECRAFT_JAR": instance.runningDirectory.appending(path: instance.config.name + ".jar").path,
                    "MINECRAFT_VERSION": instance.runningDirectory.appending(path: instance.config.name + ".jar").path,
                    "ROOT": instance.minecraftDirectory.rootURL.path,
                    "INSTALLER": installer.path,
                    "LIBRARY_DIR": instance.minecraftDirectory.librariesURL.path
                ]
            )  { (current, _) in current }
            
            // 6. 执行处理器任务
            log("正在执行 \(profile.processors.count) 个处理器任务")
            for processor in profile.processors {
                let jarPath = temp.appending(path: processor.jarPath)
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/java")
                process.arguments = [
                    "-cp", processor.classpath.map { temp.appending(path: $0).path }.union([installer.path]).joined(separator: ":"),
                    Util.getMainClass(jarPath)!
                ].union(Util.replaceTemplateStrings(processor.args.map{ parse($0, in: instance.minecraftDirectory) }, with: values))
                process.environment = ProcessInfo.processInfo.environment
                process.currentDirectoryURL = instance.runningDirectory
                do {
                    try process.run()
                    process.waitUntilExit()
                } catch {
                    err("无法执行处理器任务: \(error.localizedDescription)")
                }
            }
            
            // 7. 处理子版本
            do {
                try? FileManager.default.createDirectory(at: instance.runningDirectory.appending(path: ".pcl_mac"), withIntermediateDirectories: true)
                try FileManager.default.moveItem(
                    at: instance.runningDirectory.appending(path: "\(instance.config.name).json"),
                    to: instance.runningDirectory.appending(path: ".pcl_mac").appending(path: "\(instance.version!.displayName).json")
                )
                
                try FileManager.default.copyItem(
                    at: temp.appending(path: "version.json"),
                    to: instance.runningDirectory.appending(path: "\(instance.config.name).json")
                )
            } catch {
                err("无法保存 NeoForge 清单: \(error.localizedDescription)")
            }
            
            // 8. 清理
            Util.clearTemp()
        } else {
            err("无法获取版本列表")
        }
    }
    
    public static func parse(_ str: String, in directory: MinecraftDirectory? = nil) -> String {
        if str.hasPrefix("'") && str.hasSuffix("'") {
            return String(String(str.dropFirst()).dropLast())
        } else if str.hasPrefix("[") && str.hasSuffix("]") {
            let path = Util.toPath(mavenCoordinate: String(String(str.dropFirst()).dropLast()))
            return directory != nil ? directory!.librariesURL.appending(path: path).path : path
        }
        return str
    }
}

//
//  ModLoaderInstaller.swift
//  PCL-Mac
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
import Alamofire

public class ModLoaderInstaller {
    public static func installFabric(_ instance: MinecraftInstance, _ loaderVersion: String) async {
//        if instance.config.clientBrand != .vanilla {
//            err("无法安装 Fabric: 实例 \(instance.config.name) 已有 Mod 加载器: \(instance.config.clientBrand.rawValue)")
//        }
        
        if let data = try? await AF.request(
            "https://meta.fabricmc.net/v2/versions/loader/\(instance.version!.displayName)"
        ).serializingResponse(using: .data).value,
           let manifests = try? FabricManifest.parse(data) {
            guard let manifest = manifests.find({ $0.loaderVersion == loaderVersion }) else {
                err("找不到对应的 Fabric Loader 版本: \(loaderVersion)")
                return
            }
            
            await withCheckedContinuation { continuation in
                let downloader = ProgressiveDownloader(
                    urls: manifest.libraries.map { URL(string: $0.artifact!.url)! },
                    destinations: manifest.libraries.map { instance.minecraftDirectory.librariesUrl.appending(path: $0.artifact!.path)},
                    skipIfExists: true,
                    completion: continuation.resume
                )
                downloader.start()
            }
            
            do {
                try? FileManager.default.createDirectory(at: instance.runningDirectory.appending(path: ".pcl_mac"), withIntermediateDirectories: true)
                try FileManager.default.copyItem(
                    at: instance.runningDirectory.appending(path: "\(instance.config.name).json"),
                    to: instance.runningDirectory.appending(path: ".pcl_mac").appending(path: "\(manifest.minecraftVersion).json")
                )
                let handle = try FileHandle(forWritingTo: instance.runningDirectory.appending(path: "\(instance.config.name).json"))
                handle.truncateFile(atOffset: 0)
                try handle.write(contentsOf: manifest.jsonString.data(using: .utf8)!)
            } catch {
                err("无法保存 Fabric 清单: \(error.localizedDescription)")
            }
            
            instance.config.clientBrand = .fabric
            instance.saveConfig()
        }
    }
    
    public static func installNeoforge(_ instance: MinecraftInstance, _ version: String) async {
            if instance.config.clientBrand != .vanilla {
                err("无法安装 NeoForge: 实例 \(instance.config.name) 已有 Mod 加载器: \(instance.config.clientBrand.rawValue)")
                return
            }
        if let data = try? await AF.request(
            "https://bmclapi2.bangbang93.com/neoforge/list/\(instance.version!.displayName)"
        ).serializingResponse(using: .data).value,
            let manifests = try? NeoforgeManifest.parse(data) {
            guard let manifest = manifests.find({ $0.version == version }) else {
                err("找不到对应的 Neoforge 版本: \(version)")
                return
            }
            
            let temp = SharedConstants.shared.applicationTemperatureUrl.appending(path: "neoforge_install")
            let installer = temp.appending(path: "installer.jar")
            
            // 1. 下载安装器
            await withCheckedContinuation { continuation in
                let downloader = ProgressiveDownloader(
                    urls: [manifest.installerUrl],
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
                err("无法解析 install_profile.json: \(error)")
                return
            }
            
            // 4. 安装所需依赖
            await withCheckedContinuation { continuation in
                let downloader = ProgressiveDownloader(
                    urls: profile.libraries.map { $0.downloadUrl },
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
                    "ROOT": instance.minecraftDirectory.rootUrl.path,
                    "INSTALLER": installer.path,
                    "LIBRARY_DIR": instance.minecraftDirectory.librariesUrl.path
                ]
            )  { (current, _) in current }
            
            // 6. 执行处理器任务
            for processor in profile.processors {
                let jarPath = instance.minecraftDirectory.librariesUrl.appending(path: processor.jarPath)
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/java")
                process.arguments = [
                    "-cp", processor.classpath.map { instance.minecraftDirectory.librariesUrl.appending(path: $0).path }.union([installer.path]).joined(separator: ":"),
                    Util.getMainClass(jarPath)!
                ].union(Util.replaceTemplateStrings(processor.args.map{ parse($0, in: instance.minecraftDirectory) }, with: values))
                process.environment = ProcessInfo.processInfo.environment
                process.currentDirectoryURL = instance.runningDirectory
                do {
                    try process.run()
                    process.waitUntilExit()
                } catch {
                    err("无法调用处理器: \(error.localizedDescription)")
                }
            }
            
            // 7. 清理
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
            return directory != nil ? directory!.librariesUrl.appending(path: path).path : path
        }
        return str
    }
}

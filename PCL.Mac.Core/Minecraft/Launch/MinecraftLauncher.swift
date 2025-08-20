//
//  MinecraftLauncher.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/20.
//

import Foundation
import Cocoa

public class MinecraftLauncher {
    private let instance: MinecraftInstance
    private let id = UUID()
    public let logURL: URL
    
    public init?(_ instance: MinecraftInstance) {
        self.instance = instance
        self.logURL = SharedConstants.shared.applicationSupportURL.appending(path: "GameLogs").appending(path: id.uuidString + ".log")
        try? FileManager.default.createDirectory(at: logURL.parent(), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: logURL.path, contents: Data())
    }
    
    public func launch(_ options: LaunchOptions, _ callback: @MainActor @escaping (Int32) -> Void = { _ in }) {
        let process = Process()
        process.executableURL = options.javaPath
        process.environment = ProcessInfo.processInfo.environment
        process.arguments = []
        process.arguments!.append(contentsOf: buildJvmArguments(options))
        process.arguments!.append(instance.manifest.mainClass)
        process.arguments!.append(contentsOf: buildGameArguments(options))
        let command = process.executableURL!.path + " " + process.arguments!.joined(separator: " ")
            .replacingOccurrences(of: #"--accessToken\s+\S+"#, with: "--accessToken 🎉", options: .regularExpression)
        debug(command)
        MinecraftCrashHandler.lastLaunchCommand = command
        process.currentDirectoryURL = instance.runningDirectory
        
        if instance.config.qualityOfService.rawValue == 0 {
            instance.config.qualityOfService = .default
        }
        process.qualityOfService = instance.config.qualityOfService
        
        instance.process = process
        do {
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            let logHandle = try FileHandle(forWritingTo: logURL)
            pipe.fileHandleForReading.readabilityHandler = { handle in
                for line in String(data: handle.availableData, encoding: .utf8)!.split(separator: "\n") {
                    raw(line.replacing("\t", with: "    "))
                    try? logHandle.write(contentsOf: (line + "\n").data(using: .utf8)!)
                    logHandle.seekToEndOfFile()
                }
            }
            
            try process.run()
            
            Task { // 轮询判断窗口是否出现
                while process.isRunning {
                    let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
                    guard let windowInfoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
                        throw NSError()
                    }
                    
                    for info in windowInfoList {
                        if let windowPID = info["kCGWindowOwnerPID"] as? Int32,
                           windowPID == process.processIdentifier {
                            log("窗口已出现")
                            return
                        }
                    }
                    try await Task.sleep(for: .seconds(1))
                }
            }
            
            process.waitUntilExit()
            log("\(instance.name) 进程已退出, 退出代码 \(process.terminationStatus)")
            if process.terminationStatus == 0 {
                debug("检测到退出代码为 0，已删除日志")
                try? FileManager.default.removeItem(at: self.logURL)
            }
            DispatchQueue.main.async {
                callback(process.terminationStatus)
            }
            instance.process = nil
        } catch {
            err(error.localizedDescription)
        }
    }
    
    public func buildJvmArguments(_ options: LaunchOptions) -> [String] {
        let values: [String: String] = [
            "natives_directory": instance.runningDirectory.appending(path: "natives").path,
            "launcher_name": "PCL.Mac",
            "launcher_version": SharedConstants.shared.version,
            "classpath": buildClasspath(),
            "classpath_separator": ":",
            "library_directory": instance.minecraftDirectory.librariesURL.path,
            "version_name": instance.name,
            "authlib_injector_path": SharedConstants.shared.authlibInjectorURL.path
        ]
        
        var args: [String] = [
            "-Xmx\(instance.config.maxMemory)m",
            "-Djna.tmpdir=${natives_directory}"
        ]
        
        args.insert(contentsOf: options.yggdrasilArguments, at: 0)
        args.append(contentsOf: instance.manifest.getArguments().getAllowedJVMArguments())
        
        return Util.replaceTemplateStrings(args, with: values)
    }
    
    private func buildClasspath() -> String {
        // 去重
        ClientManifest.deduplicateLibraries(instance.manifest)
        
        var urls: [URL] = []
        for library in instance.manifest.getNeededLibraries() {
            if let artifact = library.artifact {
                urls.append(instance.minecraftDirectory.librariesURL.appending(path: artifact.path))
            }
        }
        urls.append(instance.runningDirectory.appending(path: "\(instance.name).jar"))

        return urls.map { $0.path }.joined(separator: ":")
    }
    
    private func buildGameArguments(_ options: LaunchOptions) -> [String] {
        let values: [String: String] = [
            "auth_player_name": options.playerName,
            "version_name": instance.version!.displayName,
            "game_directory": instance.runningDirectory.path,
            "assets_root": instance.minecraftDirectory.assetsURL.path,
            "assets_index_name": instance.manifest.assetIndex?.id ?? "",
            "auth_uuid": options.uuid.uuidString.replacingOccurrences(of: "-", with: "").lowercased(),
            "auth_access_token": options.accessToken,
            "user_type": "msa",
            "version_type": "PCL.Mac \(SharedConstants.shared.version)",
            "user_properties": "\"{}\""
        ]
        
        var args: [String] = []
        if options.isDemo {
            args.append("--demo")
        }
        
        return Util.replaceTemplateStrings(instance.manifest.getArguments().getAllowedGameArguments(), with: values).union(args)
    }
    
    public static func downloadAuthlibInjector() async throws {
        if FileManager.default.fileExists(atPath: SharedConstants.shared.authlibInjectorURL.path) { return }
        let json = try await Requests.get("https://bmclapi2.bangbang93.com/mirrors/authlib-injector/artifact/latest.json").getJSONOrThrow()
        guard let downloadURL = json["download_url"].url else {
            throw MyLocalizedError(reason: "无效的 authlib-injector 下载 URL")
        }
        try await Aria2Manager.shared.download(url: downloadURL, destination: SharedConstants.shared.authlibInjectorURL)
        log("authlib-injector 下载完成")
    }
}

public class LaunchState: ObservableObject {
    @Published public var isLaunched: Bool = false
}

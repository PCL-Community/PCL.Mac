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
    
    public init?(_ instance: MinecraftInstance) {
        self.instance = instance
    }
    
    public func launch(_ options: LaunchOptions) {
        let process = Process()
        process.executableURL = options.javaPath
        process.environment = ProcessInfo.processInfo.environment
        process.arguments = []
        process.arguments!.append(contentsOf: buildJvmArguments(options))
        process.arguments!.append(instance.manifest.mainClass)
        process.arguments!.append(contentsOf: buildGameArguments(options))
        debug(process.executableURL!.path + " " + process.arguments!.joined(separator: " ")
            .replacingOccurrences(of: #"--accessToken\s+\S+"#, with: "--accessToken 🎉", options: .regularExpression))
        process.currentDirectoryURL = instance.runningDirectory
        
        instance.process = process
        do {
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            pipe.fileHandleForReading.readabilityHandler = { handle in
                for line in String(data: handle.availableData, encoding: .utf8)!.split(separator: "\n") {
                    raw(line.replacing("\t", with: "    "))
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
            log("\(instance.config.name) 进程已退出, 退出代码 \(process.terminationStatus)")
            instance.process = nil
        } catch {
            err(error.localizedDescription)
        }
    }
    
    public func buildJvmArguments(_ options: LaunchOptions) -> [String] {
        let values: [String: String] = [
            "natives_directory": instance.runningDirectory.appending(path: "natives").path,
            "launcher_name": "PCL.Mac",
            "launcher_version": "1.0.0",
            "classpath": buildClasspath(),
            "classpath_separator": ":",
            "library_directory": instance.minecraftDirectory.librariesUrl.path,
            "version_name": instance.config.name
        ]
        
        var args: [String] = [
            "-Djna.tmpdir=${natives_directory}"
        ]
#if DEBUG
        args.append("-Dorg.lwjgl.util.Debug=true")
#endif
        args.append(contentsOf: instance.manifest.getArguments().getAllowedJVMArguments())
        return Util.replaceTemplateStrings(args, with: values)
    }
    
    private func buildClasspath() -> String {
        var latestMap: [String: (version: String, path: String)] = [:]

        for library in instance.manifest.getNeededLibraries() {
            if let artifact = library.artifact {
                let coord = Util.parse(mavenCoordinate: library.name)
                let key = "\(coord.groupId):\(coord.artifactId)"
                if let old = latestMap[key] {
                    if coord.version.compare(old.version, options: .numeric) == .orderedDescending {
                        latestMap[key] = (coord.version, artifact.path)
                    }
                } else {
                    latestMap[key] = (coord.version, artifact.path)
                }
            }
        }

        for coordinate in instance.config.additionalLibraries {
            let coord = Util.parse(mavenCoordinate: coordinate)
            let key = "\(coord.groupId):\(coord.artifactId)"
            let path = Util.toPath(mavenCoordinate: coordinate)
            if let old = latestMap[key] {
                if coord.version.compare(old.version, options: .numeric) == .orderedDescending {
                    latestMap[key] = (coord.version, path)
                }
            } else {
                latestMap[key] = (coord.version, path)
            }
        }

        var urls: [String] = []
        for (_, value) in latestMap {
            let path = value.path
            urls.append(instance.minecraftDirectory.librariesUrl.appending(path: path).path)
        }
        urls.append(instance.runningDirectory.appending(path: "\(instance.config.name).jar").path)

        return urls.joined(separator: ":")
    }
    
    private func buildGameArguments(_ options: LaunchOptions) -> [String] {
        let values: [String: String] = [
            "auth_player_name": options.account.name,
            "version_name": instance.version!.displayName,
            "game_directory": instance.runningDirectory.path,
            "assets_root": instance.minecraftDirectory.assetsUrl.path,
            "assets_index_name": instance.manifest.assetIndex.id,
            "auth_uuid": options.account.uuid.uuidString.replacingOccurrences(of: "-", with: "").lowercased(),
            "auth_access_token": options.account.getAccessToken(),
            "user_type": "msa",
            "version_type": "PCL Mac",
            "user_properties": "\"{}\""
        ]
        
        var args: [String] = []
        if options.isDemo {
            args.append("--demo")
        }
        
        return Util.replaceTemplateStrings(instance.manifest.getArguments().getAllowedGameArguments(), with: values).union(args)
    }
}

public class LaunchState: ObservableObject {
    @Published public var isLaunched: Bool = false
}

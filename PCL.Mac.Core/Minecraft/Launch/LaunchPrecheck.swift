//
//  LaunchPrecheck.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/20.
//

import Foundation
import AppKit

public enum JavaCheckError: Error {
    case javaNotFound
    case noUsableJava(minVersion: Int)
    case javaNotSupport
    case invalidMemoryConfiguration
    case rosetta
}

public enum AccountCheckError: Error {
    case missingAccount
    case noMicrosoftAccount
}

public class LaunchPrecheck {
    public static func checkJava(_ instance: MinecraftInstance, _ options: LaunchOptions) -> Result<Void, JavaCheckError> {
        log("[launchPrecheck] 正在进行 Java 检查")
        let suitableJava = MinecraftInstance.findSuitableJava(instance.version)
        if DataManager.shared.javaVirtualMachines
            .filter({ $0.executableURL.path != "/usr/bin/java" })
            .count == 0 {
            err("[launchPrecheck] 用户未安装 Java")
            return .failure(.javaNotFound)
        }
        
        if instance.config.maxMemory == 0 {
            return .failure(.invalidMemoryConfiguration)
        }
        
        if let suitableJava {
            if instance.config.javaURL == nil
                || !FileManager.default.fileExists(atPath: instance.config.javaURL.path) {
                instance.config.javaURL = suitableJava.executableURL
            }
            let javaArchitecture = Architecture.getArchOfFile(instance.config.javaURL!)
            
            if Architecture.system == .x64 && javaArchitecture == .arm64 {
                err("[launchPrecheck] Java 架构不兼容")
                return .failure(.javaNotSupport)
            } else if Architecture.system == .arm64 && javaArchitecture == .x64 {
                warn("[launchPrecheck] 正在使用 x64 Java")
                return .failure(.rosetta)
            }
        } else {
            let minVersion = MinecraftInstance.getMinJavaVersion(instance.version)
            err("[launchPrecheck] 无可用 Java。最低版本: \(minVersion)")
            return .failure(.noUsableJava(minVersion: minVersion))
        }
        
        return .success(())
    }
    
    public static func checkAccount(_ instance: MinecraftInstance, _ options: LaunchOptions) -> Result<Void, AccountCheckError> {
        guard let account = AccountManager.shared.getAccount() else {
            err("无法启动 Minecraft: 未设置账号")
            return .failure(.missingAccount)
        }
        
        options.account = account
        
        if !AppSettings.shared.hasMicrosoftAccount {
            debug("[launchPrecheck] 未登录过正版账号")
            return .failure(.noMicrosoftAccount)
        }
        
        return .success(())
    }
}

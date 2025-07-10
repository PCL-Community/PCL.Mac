//
//  JavaSearch.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/18.
//
// 不改了，能跑就不要动
//          by YiZhiMCQiu at 2025/6/6 in fix & optimizations (1)
// 还是改改罢，JRE 搜索炸了
//          by YiZhiMCQiu at 2025/6/28 in main

import Foundation

public class JavaSearch {
    public static func searchAndSet() throws {
        let before = Date().timeIntervalSince1970
        DataManager.shared.javaVirtualMachines = try search()
        DataManager.shared.lastTimeUsed = Int((Date().timeIntervalSince1970 - before) * 1000)
        log("搜索 Java 耗时 \(DataManager.shared.lastTimeUsed)ms")
        
        loadCustomJVMs()
    }
    
    private static func loadCustomJVMs() {
        AppSettings.shared.userAddedJvmPaths.forEach{ DataManager.shared.javaVirtualMachines.append(JavaVirtualMachine.of($0, true)) }
        log("加载了 \(AppSettings.shared.userAddedJvmPaths.count) 个由用户添加的 Java")
    }
    
    public static func search() throws -> [JavaVirtualMachine] {
        var executableUrls: [URL] = [
            URL(fileURLWithPath: "/usr/bin/java")
        ]
        
        let javaDirectoryParents = [
            "/Library/Java/JavaVirtualMachines",
            "~/Library/Java/JavaVirtualMachines",
            "/opt/homebrew/opt/java/libexec"
        ]
            .map { URL(fileURLWithUserPath: $0).path }
            .filter { FileManager.default.fileExists(atPath: $0) }
        
        for javaDirectoryParent in javaDirectoryParents {
            let parentUrl = URL(fileURLWithPath: javaDirectoryParent)
            for javaDirectory in try FileManager.default.contentsOfDirectory(atPath: javaDirectoryParent) {
                let javaHomeUrl = parentUrl.appending(path: javaDirectory).appending(path: "Contents").appending(path: "Home")
                executableUrls.append(javaHomeUrl.appending(path: "bin").appending(path: "java"))
                executableUrls.append(javaHomeUrl.appending(path: "jre").appending(path: "bin").appending(path: "java"))
            }
        }
        
        return executableUrls
            .filter { FileManager.default.fileExists(atPath: $0.path)}
            .map { JavaVirtualMachine.of($0) }
            .filter { !$0.isError }
    }
    
    private static func isValidJvmDirectory(_ path: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: toJvmDirectory(path).appending(path: "java").path(), isDirectory: &isDirectory) && !isDirectory.boolValue
    }
    
    private static func toJvmDirectory(_ path: URL) -> URL {
        return path.appending(path: "Contents").appending(path: "Home").appending(path: "bin")
    }
}

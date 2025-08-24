//
//  JavaDownloader.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/1.
//

import Foundation
import SwiftyJSON

/// Azul Zulu Java 下载 / 搜索器
public class JavaDownloader {
    private static let zuluJavaPackageNameRegex = /zulu.*-ca-fx-(jdk|jre)[0-9.]+-macosx_(x64|aarch64)\.zip/
    
    public static func search(
        version: String? = nil,
        arch: Architecture? = nil,
        type: JavaPackage.JavaType? = nil,
        onlyLTS: Bool = false,
        page: Int = 1
    ) async throws -> [JavaPackage] {
        var packages: [JavaPackage] = []
        var params: [String : String] = [
            "os": "macos",
            "archive_type": "zip",
            "latest": "true",
        ]
        
        if let version = version { params["java_version"] = version }
        if let arch = arch { params["arch"] = String(describing: arch) }
        if let type = type { params["java_package_type"] = type.rawValue }
        if onlyLTS && version == nil { params["support_term"] = "lts" }
        
        let json = try await Requests.get(
            "https://api.azul.com/metadata/v1/zulu/packages/",
            body: params,
            encodeMethod: .urlEncoded
        ).getJSONOrThrow()
        
        for package in json.arrayValue {
            if let match = package["name"].stringValue.wholeMatch(of: JavaDownloader.zuluJavaPackageNameRegex) {
                let type = String(match.1)
                let arch = String(match.2)
                
                packages.append(JavaPackage(
                    name: String(package["name"].stringValue.dropLast(4)),
                    type: .init(rawValue: type) ?? .jre,
                    arch: .fromString(arch),
                    version: package["java_version"].arrayValue.map { $0.intValue },
                    downloadURL: package["download_url"].url!
                ))
            }
        }
        
        return packages
    }
}

public class JavaInstallTask: InstallTask {
    private static let defaultJavaInstallDirectory = URL(fileURLWithUserPath: "~/Library/Java/JavaVirtualMachines")
    private let package: JavaPackage
    @Published private var progress: Double = 0
    
    public init(package: JavaPackage) {
        self.package = package
        super.init()
        self.totalFiles = 1
        self.remainingFiles = 1
    }
    
    public override func getTitle() -> String { "\(package.name) 安装" }
    
    public override func getProgress() -> Double { progress }
    
    public override func start() {
        let temp = TemperatureDirectory(name: "JavaDownload")
        Task {
            do {
                updateStage(.javaDownload)
                let zipDestination = temp.root.appending(path: "\(package.name).zip")
                try await Aria2Manager.shared.download(url: package.downloadURL, destination: zipDestination) { progress, speed in
                    self.progress = progress / 2
                    self.currentStagePercentage = progress
                }
                completeOneFile()
                updateStage(.javaInstall)
                
                Util.unzip(archiveURL: zipDestination, destination: temp.root, replace: false)
                self.progress = 0.75
                
                
                let javaDirectoryPath = temp.root.appending(path: package.name).appending(path: "zulu-\(package.version[0]).\(package.type.rawValue)")
                if !FileManager.default.fileExists(atPath: javaDirectoryPath.path) {
                    throw MyLocalizedError(reason: "发生未知错误")
                }
                
                let saveURL = JavaInstallTask.defaultJavaInstallDirectory.appending(path: javaDirectoryPath.lastPathComponent)
                
                try? FileManager.default.createDirectory(
                    at: saveURL.parent(),
                    withIntermediateDirectories: true
                )
                try? FileManager.default.copyItem(at: javaDirectoryPath, to: saveURL)
                self.progress = 1
                temp.free()
                hint("Java \(package.versionString) 安装完成！", .finish)
                complete()
            } catch {
                hint("无法安装 Java：\(error.localizedDescription)")
                complete()
            }
        }
    }
    
    public override func getInstallStates() -> [InstallStage : InstallState] {
        let allStages: [InstallStage] = [.javaDownload, .javaInstall]
        var result: [InstallStage: InstallState] = [:]
        var foundCurrent = false
        for stage in allStages {
            if foundCurrent {
                result[stage] = .waiting
            } else if self.stage == stage {
                result[stage] = .inprogress
                foundCurrent = true
            } else {
                result[stage] = .finished
            }
        }
        return result
    }
}

public struct JavaPackage: Identifiable {
    public let id: UUID = .init()
    public let name: String
    public let type: JavaType
    public let arch: Architecture
    public let version: [Int]
    public var versionString: String { version.map { String($0) }.joined(separator: ".") }
    public let downloadURL: URL
    
    public enum JavaType: String { case jre, jdk }
}

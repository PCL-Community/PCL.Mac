//
//  ModDownloader.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/19.
//

import SwiftUI
import SwiftyJSON

public class ModInstallTask: InstallTask {
    @Published public var state: InstallState = .waiting
    
    public let instance: MinecraftInstance
    private let versions: [ProjectVersion]
    
    init(instance: MinecraftInstance, versions: [ProjectVersion]) {
        self.instance = instance
        self.versions = versions
        super.init()
        self.totalFiles = versions.count
        self.remainingFiles = totalFiles
    }
    
    public override func start() {
        Task {
            await MainActor.run {
                self.state = .inprogress
            }
            
            await withCheckedContinuation { continuation in
                let downloader = ProgressiveDownloader(
                    task: self,
                    urls: versions.map { $0.downloadURL },
                    destinations: versions.map { getDestinationDirectory($0).appending(path: $0.downloadURL.lastPathComponent) },
                    skipIfExists: true,
                    completion: continuation.resume
                )
                downloader.start()
            }
            complete()
        }
    }
    
    private func getDestinationDirectory(_ version: ProjectVersion) -> URL {
        let base = instance.runningDirectory
        return switch version.projectType {
        case .mod: base.appending(path: "mods")
        case .resourcepack: base.appending(path: "resourcepacks")
        case .shader: base.appending(path: "shaderpacks")
        }
    }
    
    public override func getInstallStates() -> [InstallStage : InstallState] { [.mods : state] }
    public override func getTitle() -> String { "模组下载" }
}


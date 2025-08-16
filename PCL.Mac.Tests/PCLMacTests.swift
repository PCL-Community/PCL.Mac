//
//  PCL_MacTests.swift
//  PCL.MacTests
//
//  Created by YiZhiMCQiu on 2025/5/18.
//

import Foundation
import Testing
import PCL_Mac
import SwiftUI
import Cocoa
import UserNotifications
import SwiftyJSON

struct PCL_MacTests {
    @Test func testDownload() async {
        await withCheckedContinuation { continuation in
            let task = MinecraftInstaller.createTask(.init(displayName: "1.21.8"), "1.21.8", .default, continuation.resume)
            task.start()
        }
    }
    
    @Test func testLibraries() {
        guard let instance = MinecraftInstance.create(.init(rootURL: URL(fileURLWithUserPath: "~/PCL-Mac-minecraft"), name: ""), URL(fileURLWithUserPath: "~/PCL-Mac-minecraft/versions/1.8.9-Forge 11.15.0.1656")) else {
            fatalError()
        }
        
        print(instance.manifest.getNeededLibraries().count)
        for library in instance.manifest.getNeededLibraries() {
            print(library.name)
        }
    }
}

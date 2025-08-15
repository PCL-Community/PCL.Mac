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
    
    func replaceWithValue(_ string: String) -> String {
        let values = ["foo": "bar", "test": "success"]
        if !string.contains("{") || !string.contains("}") { return string }
        
        for (key, value) in values {
            if string.contains("{\(key)}") {
                return string.replacingOccurrences(of: "{\(key)}", with: value)
            }
        }
        
        return string
    }
    
    @Test func testLibraries() {
        print(replaceWithValue("{foo}"))
//        guard let instance = MinecraftInstance.create(.default, URL(fileURLWithUserPath: "~/minecraft/versions/23w13a_or_b")) else {
//            fatalError()
//        }
//        
//        for library in instance.manifest.getNeededLibraries() {
//            print(library.artifact!.path)
//        }
    }
}

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
import Alamofire
import SwiftyJSON

struct PCL_MacTests {
    @Test func testRun() async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let versionUrl = URL(fileURLWithUserPath: "~/PCL-Mac-minecraft/versions/1.21 Test")
        let instance = MinecraftInstance.create(runningDirectory: versionUrl)
        await instance!.launch()
    }
    
    @Test func testLoadClientManifest() async throws {
        let handle = try FileHandle(forReadingFrom: URL(fileURLWithUserPath: "~/PCL-Mac-minecraft/versions/1.12.2/1.12.2.json"))
        let manifest = try ClientManifest.parse(try handle.readToEnd()!, instanceUrl: nil)
        ArtifactVersionMapper.map(manifest)
        print(manifest.getNeededNatives().map { "\($0.key.name): \($0.value.url)" })
    }
    
    @Test func testDownload() async throws {
        await withCheckedContinuation { continuation in
            MinecraftInstaller.createTask(MinecraftVersion(displayName: "1.14"), "1.14", MinecraftDirectory(rootUrl: URL(fileURLWithUserPath: "~/PCL-Mac-minecraft"))) {
                continuation.resume()
            }.start()
        }
    }
    
    @Test func testFetchVersionsManifest() async throws {
        if let manifest = await VersionManifest.fetchLatestData() {
            print(manifest.versions.first!.parse().displayName)
        }
    }
    
    @Test func testMinecraftDirectory() async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        DispatchQueue.main.schedule(after: DispatchQueue.SchedulerTimeType(DispatchTime(uptimeNanoseconds: 2000000000))) {
            print("1.21.6 最合适的 Java 是: " + MinecraftInstance.findSuitableJava(MinecraftVersion(displayName: "1.21.6"))!.executableUrl.path())
        }
    }
    
    @Test func testMsLogin() async throws {
        try await Task.sleep(nanoseconds: 5_000_000_000)
        print(AccountManager.shared.getAccount()!.getAccessToken())
    }
    
    @Test func testNotifaction() async throws {
        UNUserNotificationCenter.current().setNotificationCategories([])
        
        let content = UNMutableNotificationContent()
        content.title = "登录"
        content.body = "请将剪切板中的内容粘贴到输入框中"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 立即触发
        )
        try await UNUserNotificationCenter.current().add(request)
    }
    
    @Test func testNetwork() async throws {
        print(NetworkTest.shared.hasNetworkConnection())
    }
    
    @Test func testTheme() async {
        await ThemeDownloader.downloadTheme(.venti)
    }
    
    @Test func testSymbolicLink() throws {
        let start = DispatchTime.now()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/libexec/java_home")
        try! process.run()
        process.waitUntilExit()
        print("耗时: \(Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000) 毫秒")
    }
    
    @Test func testWindow() throws {
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        guard let windowInfoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            throw NSError()
        }
        
        for info in windowInfoList {
            if let windowOwnerName = info["kCGWindowOwnerName"] as? String,
                windowOwnerName.lowercased().contains("java") {
                print(info)
            }
        }
    }
    
    @Test func testCompleteResource() async {
        await withCheckedContinuation { continuation in
            let task = MinecraftInstaller.createCompleteTask(MinecraftInstance.create(runningDirectory: URL(fileURLWithUserPath: "~/PCL-Mac-minecraft/versions/1.21.5"))!, continuation.resume)
            task.start()
        }
    }
    
    @Test func testModLoader() async throws {
        Util.clearTemp()
        let instance = MinecraftInstance.create(runningDirectory: URL(fileURLWithUserPath: "~/PCL-Mac-minecraft/versions/1.21.7 NeoForge"))!
        await ModLoaderInstaller.installNeoforge(instance, "21.7.2-beta")
    }
    
    @Test func testMavenCoord() async {
        print(Util.toPath(mavenCoordinate: "net.neoforged:neoform:1.21.5-20250325.162830@txt"))
    }
    
    @Test func testModSearch() async throws {
        let summaries = await ModrinthModSearcher.default.search(query: "sodium")
        for summary in summaries {
            print("\(await summary.title) \(await summary.infoUrl)")
        }
    }
    
    @Test func testOfflineAccount() {
        let account = OfflineAccount("PCL_Mac")
        print(account.uuid.uuidString.replacingOccurrences(of: "-", with: "").lowercased())
    }
}

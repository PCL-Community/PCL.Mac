//
//  Aria2Manager.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/2/25.
//

import Foundation

public class Aria2Manager {
    public static let shared: Aria2Manager = .init()
    
    public let executableURL: URL
    
    public func download(url: URL, destination: URL) async throws {
        guard FileManager.default.fileExists(atPath: executableURL.path) else {
            throw NSError(domain: "aria2", code: 404, userInfo: [NSLocalizedDescriptionKey: "未安装 aria2！"])
        }
        
        do {
            let process = Process()
            process.executableURL = executableURL
            process.currentDirectoryURL = executableURL.parent()
            process.arguments = [url.absoluteString, "-d", destination.parent().path, "-o", destination.lastPathComponent]
            try process.run()
            await withCheckedContinuation { continuation in
                process.waitUntilExit()
                continuation.resume()
            }
        } catch {
            throw error
        }
    }
    
    public func downloadAria2() async throws {
        guard !FileManager.default.fileExists(atPath: executableURL.path) else {
            throw NSError(domain: "aria2", code: 404, userInfo: [NSLocalizedDescriptionKey: "已安装 aria2！"])
        }
        let data = try await Requests.get("https://gitee.com/yizhimcqiu/aria2-macos-universal/raw/master/aria2c-macos-universal").getDataOrThrow()
        FileManager.default.createFile(atPath: executableURL.path, contents: data)
        chmod(executableURL.path, 0o755)
    }
    
    private init() {
        executableURL = SharedConstants.shared.applicationSupportUrl.appending(path: "Aria2").appending(path: "aria2c")
        try? FileManager.default.createDirectory(at: executableURL.parent(), withIntermediateDirectories: true)
    }
}

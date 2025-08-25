//
//  Aria2Manager.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/2/25.
//

import Foundation
import SwiftyJSON

public class Aria2Manager {
    public static let shared: Aria2Manager = .init()
    
    public let executableURL: URL
    private let port: Int?
    
    public func download(url: URL, destination: URL, progress: ((Double, Int) -> Void)? = nil) async throws {
        try await download(urls: [url], destination: destination, progress: progress)
    }
    
    public func download(urls: [URL], destination: URL, progress: ((Double, Int) -> Void)? = nil) async throws {
        guard FileManager.default.fileExists(atPath: executableURL.path) else {
            throw MyLocalizedError(reason: "\(executableURL.path) 不存在")
        }
        
        let id = try await sendRpc("aria2.addUri", [
            urls.map { $0.absoluteString },
            [
                "dir": destination.parent().path,
                "out": destination.lastPathComponent,
                "split": "64",
                "max-connection-per-server": "16",
                "enable-http-pipelining": "true",
                "check-integrity": "false",
                "header": [
                    "User-Agent: PCLMac/\(SharedConstants.shared.version)"
                ]
            ]
        ]).stringValue
        debug("开始下载 \(urls[0].absoluteString)")
        
        while true {
            let response = try await sendRpc("aria2.tellStatus", [id, ["downloadSpeed", "totalLength", "completedLength", "status"]])
            let status = response["status"].stringValue
            if status == "error" {
                err("\(id) 状态切换为 error: \(response.rawString()!)")
                throw MyLocalizedError(reason: "发生未知错误")
            } else if status == "complete" {
                break
            }
            await MainActor.run {
                progress?(Double(response["completedLength"].intValue) / Double(response["totalLength"].intValue), response["downloadSpeed"].intValue)
            }
            
            try? await Task.sleep(for: .seconds(0.2))
        }
    }
    
    public func sendRpc(_ method: String, _ params: [Any]) async throws -> JSON {
        guard let port = port else {
            throw MyLocalizedError(reason: "进程未正常启动")
        }
        let body: [String : Any] = [
            "id": UUID().uuidString,
            "jsonrpc": "2.0",
            "method": method,
            "params": params
        ]
        let json = try await Requests.post("http://localhost:\(port)/jsonrpc", body: body, encodeMethod: .json).getJSONOrThrow()
        if json["error"].exists() {
            throw MyLocalizedError(reason: json["error"].rawString()!)
        }
        return json["result"]
    }
    
    public func downloadAria2() async throws {
        guard !FileManager.default.fileExists(atPath: executableURL.path) else {
            throw MyLocalizedError(reason: "\(executableURL.path) 已存在")
        }
        try await SingleFileDownloader.download(url: "https://gitee.com/yizhimcqiu/aria2-macos-universal/raw/master/aria2c-macos-universal".url, destination: executableURL, replaceMethod: .replace)
        chmod(executableURL.path, 0o755)
    }
    
    public func checkAndDownloadAria2() {
        if !FileManager.default.fileExists(atPath: executableURL.path) {
            Task {
                do {
                    try await downloadAria2()
                } catch {
                    await PopupManager.shared.show(
                        .init(.error, "无法下载 aria2c", "\(error.localizedDescription)\n你可以点击重试，或手动将 aria2c 可执行文件下载至 \(executableURL.path)", [.init(label: "重试", style: .normal), .ok]),
                    ) { button in
                        if button == 0 { self.checkAndDownloadAria2() }
                    }
                }
            }
        }
    }
    
    private init() {
        executableURL = SharedConstants.shared.applicationSupportURL.appending(path: "Aria2").appending(path: "aria2c")
        try? FileManager.default.createDirectory(at: executableURL.parent(), withIntermediateDirectories: true)
        guard FileManager.default.fileExists(atPath: executableURL.path) else {
            self.port = nil
            return
        }
        self.port = Int.random(in: 25566...32768)
        
        let process = Process()
        process.executableURL = executableURL
        process.currentDirectoryURL = executableURL.parent()
        process.arguments = ["--enable-rpc", "--rpc-listen-port=\(port!)"]
        
        process.standardOutput = nil
        process.standardError = nil
        
        do {
            try process.run()
            log("aria2c 已启动")
        } catch {
            err("无法启动 aria2c: \(error.localizedDescription)")
        }
    }
    
    public func shutdown() async {
        let _ = try? await sendRpc("aria2.shutdown", [])
    }
}

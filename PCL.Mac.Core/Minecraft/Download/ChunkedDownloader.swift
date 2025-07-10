//
//  ChunkedDownloader.swift
//  PCL.Mac
//
//  Created by Claude on 2025/6/1.
//

import Foundation

/// 用于大文件分块下载的类
public class ChunkedDownloader {
    private let url: URL
    private let destination: URL
    private let chunkCount: Int
    private let task: InstallTask
    private let completion: () -> Void
    private var downloadedChunks: [Int: Data] = [:]
    private var finishedChunks: Int = 0
    private var fileSize: Int64 = 0
    private let lock = NSLock()
    private var session: URLSession!
    private var startTime: Date?
    
    /// 初始化分块下载器
    /// - Parameters:
    ///   - url: 下载源URL
    ///   - destination: 目标文件位置
    ///   - chunkCount: 分块数量
    ///   - task: 安装任务
    ///   - completion: 完成回调
    public init(url: URL, destination: URL, chunkCount: Int, task: InstallTask, completion: @escaping () -> Void) {
        self.url = url
        self.destination = destination
        self.chunkCount = min(max(chunkCount, 1), 32) // 限制在1-32之间
        self.task = task
        self.completion = completion
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = self.chunkCount
        config.timeoutIntervalForRequest = 30 // 30秒超时
        config.timeoutIntervalForResource = 60 // 60秒资源超时
        session = URLSession(configuration: config, delegate: nil, delegateQueue: OperationQueue())
    }
    
    /// 开始下载
    public func start() {
        startTime = Date()
        debug("开始下载文件: \(url.absoluteString)")
        
        // 设置超时计时器
        DispatchQueue.global().asyncAfter(deadline: .now() + 30) { [weak self] in
            guard let self = self else { return }
            // 检查是否已经完成
            if self.finishedChunks == 0 {
                debug("下载超时，尝试单线程下载: \(self.url.lastPathComponent)")
                self.downloadSingleThread()
            }
        }
        
        // 先获取文件大小
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        let task = session.dataTask(with: request) { [weak self] _, response, error in
            guard let self = self else { return }
            
            if let error = error {
                debug("获取文件大小失败: \(error.localizedDescription)，改为单线程下载")
                self.downloadSingleThread()
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                debug("获取文件大小失败: 无效的响应，改为单线程下载")
                self.downloadSingleThread()
                return
            }
            
            // 检查HTTP状态码
            guard (200...299).contains(response.statusCode) else {
                debug("获取文件大小失败: HTTP状态码 \(response.statusCode)，改为单线程下载")
                self.downloadSingleThread()
                return
            }
            
            if let contentLength = response.value(forHTTPHeaderField: "Content-Length"),
               let size = Int64(contentLength), size > 0 {
                self.fileSize = size
                debug("文件大小: \(size) 字节, 将使用 \(self.chunkCount) 个线程下载")
                
                // 如果文件太小，不使用分块下载
                if size < 1024 * 1024 { // 小于1MB
                    self.downloadSingleThread()
                    return
                }
                
                self.downloadInChunks(fileSize: size)
            } else {
                debug("无法获取文件大小，改为单线程下载")
                self.downloadSingleThread()
            }
        }
        task.resume()
    }
    
    /// 单线程下载（备用方案）
    private func downloadSingleThread() {
        debug("开始单线程下载: \(url.lastPathComponent)")
        
        // 创建下载请求
        var request = URLRequest(url: url)
        request.timeoutInterval = 60 // 60秒超时
        
        // 尝试使用官方源
        let officialUrl = URL(string: url.absoluteString.replacingOccurrences(
            of: "bmclapi2.bangbang93.com",
            with: "launcher.mojang.com/v1/objects"
        ))
        
        if let officialUrl = officialUrl, officialUrl != url {
            debug("尝试使用官方源: \(officialUrl.absoluteString)")
            
            // 创建一个新的请求使用官方源
            var officialRequest = URLRequest(url: officialUrl)
            officialRequest.timeoutInterval = 60
            
            let officialTask = session.downloadTask(with: officialRequest) { [weak self] location, response, error in
                guard let self = self else { return }
                
                if let error = error {
                    debug("官方源下载失败: \(error.localizedDescription)，尝试原始源")
                    self.downloadFromOriginalSource(request)
                    return
                }
                
                guard let location = location else {
                    debug("官方源下载失败: 未获取到文件位置，尝试原始源")
                    self.downloadFromOriginalSource(request)
                    return
                }
                
                // 处理下载成功的情况
                self.processDownloadedFile(location)
            }
            officialTask.resume()
        } else {
            // 直接使用原始源
            downloadFromOriginalSource(request)
        }
    }
    
    private func downloadFromOriginalSource(_ request: URLRequest) {
        debug("使用原始源下载: \(url.absoluteString)")
        let task = session.downloadTask(with: request) { [weak self] location, response, error in
            guard let self = self else { return }
            
            if let error = error {
                err("下载失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.completion()
                }
                return
            }
            
            guard let location = location else {
                err("下载失败: 未获取到文件位置")
                DispatchQueue.main.async {
                    self.completion()
                }
                return
            }
            
            // 处理下载成功的情况
            self.processDownloadedFile(location)
        }
        task.resume()
    }
    
    private func processDownloadedFile(_ location: URL) {
        // 检查HTTP状态码
        do {
            let dir = self.destination.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            if FileManager.default.fileExists(atPath: self.destination.path) {
                try FileManager.default.removeItem(at: self.destination)
            }
            try FileManager.default.moveItem(at: location, to: self.destination)
            debug("单线程下载完成: \(self.url.lastPathComponent)")
            self.task.completeOneFile()
            
            DispatchQueue.main.async {
                self.completion()
            }
        } catch {
            err("保存文件失败: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.completion()
            }
        }
    }
    
    /// 分块下载
    /// - Parameter fileSize: 文件总大小
    private func downloadInChunks(fileSize: Int64) {
        let chunkSize = fileSize / Int64(chunkCount)
        
        for i in 0..<chunkCount {
            let start = Int64(i) * chunkSize
            let end = i == chunkCount - 1 ? fileSize - 1 : start + chunkSize - 1
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("bytes=\(start)-\(end)", forHTTPHeaderField: "Range")
            
            let task = session.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let error = error {
                    err("分块 \(i) 下载失败: \(error.localizedDescription)")
                    // 如果发生错误，我们仍然继续下载其他分块
                    // 但是我们需要记录错误状态
                    self.lock.lock()
                    self.finishedChunks += 1
                    self.lock.unlock()
                    
                    // 如果所有分块都已处理（包括失败的），则完成下载
                    if self.finishedChunks == self.chunkCount {
                        // 如果有分块失败，使用单线程下载
                        debug("部分分块下载失败，切换到单线程下载")
                        self.downloadSingleThread()
                    }
                    return
                }
                
                guard let data = data else {
                    err("分块 \(i) 下载失败: 未获取到数据")
                    self.lock.lock()
                    self.finishedChunks += 1
                    self.lock.unlock()
                    
                    if self.finishedChunks == self.chunkCount {
                        debug("部分分块下载失败，切换到单线程下载")
                        self.downloadSingleThread()
                    }
                    return
                }
                
                self.lock.lock()
                self.downloadedChunks[i] = data
                self.finishedChunks += 1
                
                // 更新进度
                let progress = Double(self.finishedChunks) / Double(self.chunkCount)
                let elapsed = Date().timeIntervalSince(self.startTime ?? Date())
                let speed = elapsed > 0 ? Double(data.count * self.finishedChunks) / elapsed : 0
                
                DispatchQueue.main.async {
                    DataManager.shared.downloadSpeed = speed
                    self.task.currentStagePercentage = progress
                }
                
                // 检查是否所有分块都已下载完成
                if self.finishedChunks == self.chunkCount {
                    self.lock.unlock()
                    self.mergeChunks()
                } else {
                    self.lock.unlock()
                }
            }
            task.resume()
        }
    }
    
    /// 合并所有分块
    private func mergeChunks() {
        do {
            // 检查是否所有分块都已下载
            for i in 0..<chunkCount {
                if downloadedChunks[i] == nil {
                    debug("缺少分块 \(i)，切换到单线程下载")
                    downloadSingleThread()
                    return
                }
            }
            
            let dir = self.destination.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            if FileManager.default.fileExists(atPath: self.destination.path) {
                try FileManager.default.removeItem(at: self.destination)
            }
            
            FileManager.default.createFile(atPath: self.destination.path, contents: nil)
            let fileHandle = try FileHandle(forWritingTo: self.destination)
            
            for i in 0..<chunkCount {
                if let chunkData = downloadedChunks[i] {
                    fileHandle.write(chunkData)
                } else {
                    throw NSError(domain: "ChunkedDownloader", code: 1, userInfo: [NSLocalizedDescriptionKey: "缺少分块 \(i)"])
                }
            }
            
            try fileHandle.close()
            self.task.completeOneFile()
            
            DispatchQueue.main.async {
                self.completion()
            }
        } catch {
            err("合并分块失败: \(error.localizedDescription)")
            // 如果合并失败，使用单线程下载
            downloadSingleThread()
        }
    }
}

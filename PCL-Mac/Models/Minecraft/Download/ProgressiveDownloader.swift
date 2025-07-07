//
//  ProgressiveDownloader.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/5/31.
//

import Foundation

public final class ProgressiveDownloader: NSObject, URLSessionDownloadDelegate {
    public let task: InstallTask?
    public let urls: [URL]
    public let destinations: [URL]
    public let concurrentLimit: Int
    public let skipIfExists: Bool
    public let progressCallback: ((Int, Int, Double, Double) -> Void)?
    public var completion: (() -> Void)?
    public var finishedCount = 0
    private var session: URLSession!
    private var startTime: Date?
    private var fileSizeMap: [Int : Int64] = [:]
    private var bytesMap: [Int : Int64] = [:]
    private let lock = NSLock()
    private var nextIndex: Int = 0

    public init(task: InstallTask? = nil, urls: [URL], destinations: [URL], concurrentLimit: Int = 4, skipIfExists: Bool = false,
                progress: ((Int, Int, Double, Double) -> Void)? = nil,
                completion: (() -> Void)? = nil) {
        self.task = task
        self.urls = urls
        self.destinations = destinations
        self.concurrentLimit = concurrentLimit
        self.skipIfExists = skipIfExists
        self.progressCallback = progress
        self.completion = completion
        super.init()
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = concurrentLimit
        session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }

    public func start() {
        startTime = Date()
        lock.lock()
        nextIndex = 0
        lock.unlock()
        for _ in 0..<min(concurrentLimit, urls.count) {
            startNextTask()
        }
    }

    public func startNextTask() {
        while true {
            lock.lock()
            let index = nextIndex
            nextIndex += 1
            lock.unlock()
            guard index < urls.count else { return }
            let dest = destinations[index]
            if skipIfExists && FileManager.default.fileExists(atPath: dest.path) {
                debug("\(dest.path) 已存在，跳过")
                lock.lock()
                finishedCount += 1
                task?.completeOneFile()
                lock.unlock()
                updateProgress()
                if finishedCount == urls.count {
                    session.invalidateAndCancel()
                    DispatchQueue.main.async {
                        self.completion?()
                        self.completion = nil
                    }
                }
                continue
            }
            let request = URLRequest(url: urls[index])
            let task = session.downloadTask(with: request)
            task.taskDescription = "\(index)"
            task.resume()
            break
        }
    }

    private func computeProgress() -> (progress: Double, downloaded: Int64, expected: Int64, speed: Double) {
        var partialProgress: Double = 0.0
        var totalDownloaded: Int64 = 0
        var totalExpected: Int64 = 0

        lock.lock()
        for (index, _) in urls.enumerated() {
            if let fileSize = fileSizeMap[index], let bytes = bytesMap[index], fileSize > 0 {
                if bytes >= fileSize {
                    continue
                } else {
                    partialProgress += min(1.0, Double(bytes) / Double(fileSize))
                }
            }
        }
        let completed = Double(finishedCount)
        let total = Double(urls.count)
        let progress = min(1.0, (completed + partialProgress) / total)

        totalDownloaded = bytesMap.values.reduce(0, +)
        totalExpected = fileSizeMap.values.reduce(0, +)

        let elapsed = Date().timeIntervalSince(startTime ?? Date())
        let speed = elapsed > 0 ? Double(totalDownloaded) / elapsed : 0

        lock.unlock()
        return (progress, totalDownloaded, totalExpected, speed)
    }

    private func updateProgress() {
        let (progress, _, _, speed) = computeProgress()
        DispatchQueue.main.async {
            self.progressCallback?(self.finishedCount, self.urls.count, progress, speed)
            DataManager.shared.downloadSpeed = speed
            self.task?.currentStagePercentage = progress
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        guard let strIndex = downloadTask.taskDescription, let index = Int(strIndex) else { return }
        lock.lock()
        bytesMap[index] = totalBytesWritten
        if totalBytesExpectedToWrite > 0 {
            if let old = fileSizeMap[index] {
                if totalBytesExpectedToWrite > old {
                    fileSizeMap[index] = totalBytesExpectedToWrite
                }
            } else {
                fileSizeMap[index] = totalBytesExpectedToWrite
            }
        }
        lock.unlock()
        updateProgress()
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let strIndex = downloadTask.taskDescription, let index = Int(strIndex) else { return }
        let dest = destinations[index]
        var fileSize: Int64 = 0
        do {
            let dir = dest.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.moveItem(at: location, to: dest)
            let attr = try FileManager.default.attributesOfItem(atPath: dest.path)
            fileSize = (attr[.size] as? Int64) ?? 0
        } catch {}

        lock.lock()
        finishedCount += 1
        task?.completeOneFile()
        if fileSize > 0, (fileSizeMap[index] ?? 0) < fileSize {
            fileSizeMap[index] = fileSize
            bytesMap[index] = fileSize
        }
        lock.unlock()
        updateProgress()
        startNextTask()
        if finishedCount == urls.count {
            session.invalidateAndCancel()
            DispatchQueue.main.async {
                self.completion?()
                self.completion = nil
            }
        }
    }
}

//
//  ChunkedDownloader.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/1.
//

import Foundation

public class ChunkedDownloader {
    private let url: URL
    private let destination: URL
    private let chunkCount: Int
    private var chunkTasks: [URLSessionDownloadTask] = []
    private var chunkTempFiles: [Int: URL] = [:]
    private var chunkErrors: [Int: Error] = [:]
    private let queue = DispatchQueue(label: "ChunkedDownloader.queue", attributes: .concurrent)
    private let group = DispatchGroup()
    private var totalSize: Int64 = 0
    private let onChunkDownloaded: ((Int, Int) -> Void)?
    private var finishedChunkCount: Int = 0
    private let tempDir: URL
    private let session = URLSession(configuration: .default)

    public init(url: URL, destination: URL, chunkCount: Int, onChunkDownloaded: ((Int, Int) -> Void)? = nil) {
        self.url = url
        self.destination = destination
        self.chunkCount = chunkCount
        self.onChunkDownloaded = onChunkDownloaded
        self.tempDir = SharedConstants.shared.temperatureUrl
            .appending(path: "ChunkedDownload")
            .appending(path: UUID().uuidString)
    }

    public func start() async {
        do {
            guard let size = await fetchContentLength() else {
                throw NSError(domain: "ChunkedDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Content-Length"])
            }
            self.totalSize = size
            try await self.downloadChunks(size: size)
        } catch {
            debug("无法进行分片下载：\(error.localizedDescription)，正在使用单线程下载 \(url.lastPathComponent)")
            try? await Requests.get(url).data?.write(to: destination)
        }
    }

    private func fetchContentLength() async -> Int64? {
        await withCheckedContinuation { continuation in
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            let task = URLSession.shared.dataTask(with: request) { (_, response, error) in
                if let error = error {
                    err("HEAD 请求失败: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse,
                      let contentLengthStr = httpResponse.allHeaderFields["Content-Length"] as? String,
                      let contentLength = Int64(contentLengthStr) else {
                    err("响应头中没有 Content-Length")
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: contentLength)
            }
            task.resume()
        }
    }

    private func downloadChunks(size: Int64) async throws {
        guard chunkCount > 0, size > 0 else {
            throw NSError(domain: "ChunkedDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid chunkCount or size"])
        }
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let baseChunkSize = size / Int64(chunkCount)
        let remainder = size % Int64(chunkCount)
        var offset: Int64 = 0

        for i in 0..<chunkCount {
            let extra = i < remainder ? 1 : 0
            let thisChunkSize = baseChunkSize + Int64(extra)
            let start = offset
            let end = start + thisChunkSize - 1
            if start > end { continue }
            group.enter()
            downloadChunk(index: i, range: start...end)
            offset += thisChunkSize
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            group.notify(queue: queue) { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "ChunkedDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                    return
                }
                do {
                    try self.writeChunksToFile()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        }

        try? FileManager.default.removeItem(at: tempDir)
    }

    private func downloadChunk(index: Int, range: ClosedRange<Int64>) {
        var request = URLRequest(url: url)
        request.setValue("bytes=\(range.lowerBound)-\(range.upperBound)", forHTTPHeaderField: "Range")
        let tempFile = tempDir.appendingPathComponent("chunk_\(index)")
        let task = session.downloadTask(with: request) { [weak self] location, response, error in
            defer { self?.group.leave() }
            guard let self = self else { return }
            if let error = error {
                err("分片 \(index) 下载失败: \(error.localizedDescription)")
                self.queue.async(flags: .barrier) {
                    self.chunkErrors[index] = error
                }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                err("分片 \(index) 无 HTTP 响应")
                return
            }
            guard httpResponse.statusCode == 206 else {
                if httpResponse.statusCode == 429 { return }
                err("分片 \(index) 没有返回 206 Partial Content (\(httpResponse.statusCode))")
                self.queue.async(flags: .barrier) {
                    self.chunkErrors[index] = NSError(domain: "ChunkedDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "ChunkedDownloader"])
                }
                return
            }
            if let location = location {
                do {
                    if FileManager.default.fileExists(atPath: tempFile.path) {
                        try FileManager.default.removeItem(at: tempFile)
                    }
                    try FileManager.default.moveItem(at: location, to: tempFile)
                    self.queue.async(flags: .barrier) {
                        self.chunkTempFiles[index] = tempFile
                        self.finishedChunkCount += 1
                    }
                    self.onChunkDownloaded?(self.finishedChunkCount, self.chunkCount)
                } catch {
                    err("分片 \(index) 临时文件保存失败: \(error)")
                    self.queue.async(flags: .barrier) {
                        self.chunkErrors[index] = error
                    }
                }
            }
        }
        task.resume()
        queue.async(flags: .barrier) {
            self.chunkTasks.append(task)
        }
    }

    private func writeChunksToFile() throws {
        guard chunkErrors.isEmpty else {
            throw chunkErrors.values.first!
        }

        let sortedChunkFiles = (0..<chunkCount).compactMap { chunkTempFiles[$0] }
        guard sortedChunkFiles.count == chunkCount else {
            err("区块文件缺失 (\(sortedChunkFiles.count)/\(chunkCount))")
            throw NSError(domain: "ChunkedDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "区块文件缺失"])
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try? FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: destination.path, contents: nil, attributes: nil)
        guard let fileHandle = try? FileHandle(forWritingTo: destination) else {
            throw NSError(domain: "ChunkedDownloader", code: -2, userInfo: [NSLocalizedDescriptionKey: "无法打开目标文件"])
        }

        for tempFile in sortedChunkFiles {
            guard let chunkHandle = try? FileHandle(forReadingFrom: tempFile) else {
                throw NSError(domain: "ChunkedDownloader", code: -3, userInfo: [NSLocalizedDescriptionKey: "无法打开分片文件"])
            }
            while true {
                let data = try chunkHandle.read(upToCount: 1024 * 128)
                if let data = data, !data.isEmpty {
                    fileHandle.write(data)
                } else {
                    break
                }
            }
            try? chunkHandle.close()
        }
        try? fileHandle.close()
    }
}

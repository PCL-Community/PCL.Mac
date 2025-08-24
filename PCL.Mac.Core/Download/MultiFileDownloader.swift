//
//  ProgressiveDownloader.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/24.
//

import Foundation

public struct DownloadItem {
    fileprivate let url: URL
    fileprivate let destination: URL
    
    fileprivate var fallbackURL: URL? {
        fallbackURLProvider?()
    }
    private var fallbackURLProvider: (() -> URL)?
    
    public init(_ downloadSource: DownloadSource, _ urlProvider: @escaping (DownloadSource) -> URL, destination: URL) {
        self.url = urlProvider(downloadSource)
        self.fallbackURLProvider = { urlProvider(OfficialDownloadSource.shared) }
        self.destination = destination
    }
    
    public init(_ url: URL, _ destination: URL) {
        self.url = url
        self.destination = destination
    }
}

public class MultiFileDownloader {
    private let items: [DownloadItem]
    private let concurrentLimit: Int
    private let replaceMethod: ReplaceMethod
    private let progress: ((Double, Int) -> Void)?
    private let total: Int
    private var totalProgress: Double = 0
    private var finishedCount: Int = 0
    
    public init(
        items: [DownloadItem],
        concurrentLimit: Int,
        replaceMethod: ReplaceMethod = .skip,
        progress: ((Double, Int) -> Void)? = nil
    ) {
        self.items = items
        self.concurrentLimit = concurrentLimit
        self.replaceMethod = replaceMethod
        self.progress = progress
        self.total = items.count
    }
    
    public func start() async throws {
        guard !items.isEmpty else { return }
        if concurrentLimit == 1 {
            for item in items {
                try await attemptDownload(item)
            }
            return
        }
        
        var tickerTask: Task<Void, Error>? = nil
        if let progress = progress {
            tickerTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(0.02))
                    if Task.isCancelled { break }
                    progress(self.totalProgress / Double(self.total), self.finishedCount)
                }
            }
        }
        
        defer {
            tickerTask?.cancel()
        }
        
        var nextIndex = 0
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            let initial = min(concurrentLimit, total)
            while nextIndex < initial {
                let item = items[nextIndex]
                group.addTask {
                    try await self.attemptDownload(item)
                }
                nextIndex += 1
            }
            
            while let _ = try await group.next() {
                if nextIndex < total {
                    let item = items[nextIndex]
                    group.addTask {
                        try await self.attemptDownload(item)
                    }
                    nextIndex += 1
                }
            }
        }
    }
    
    private func attemptDownload(_ item: DownloadItem) async throws {
        if FileManager.default.fileExists(atPath: item.destination.path) && replaceMethod == .throw {
            throw MyLocalizedError(reason: "\(item.destination.lastPathComponent) 已存在。")
        }
        
        var lastProgress: Double = 0
        
        do {
            try await SingleFileDownloader.download(url: item.url, destination: item.destination, replaceMethod: replaceMethod) { progress in
                self.totalProgress += (progress - lastProgress)
                lastProgress = progress
            }
        } catch {
            guard let fallback = item.fallbackURL else {
                throw error
            }
            try await SingleFileDownloader.download(url: fallback, destination: item.destination, replaceMethod: .replace) { progress in
                self.totalProgress += (progress - lastProgress)
                lastProgress = progress
            }
        }
        
        finishedCount += 1
    }
}

public enum ReplaceMethod {
    case skip, replace, `throw`
}

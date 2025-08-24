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

public class NewProgressiveDownloader {
    public static func download(items: [DownloadItem], concurrentLimit: Int) async throws {
        guard !items.isEmpty else { return }
        if concurrentLimit == 1 {
            for item in items {
                try await attemptDownload(item)
            }
            return
        }
        
        var nextIndex = 0
        let total = items.count
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            let initial = min(concurrentLimit, total)
            while nextIndex < initial {
                let item = items[nextIndex]
                group.addTask {
                    try await attemptDownload(item)
                }
                nextIndex += 1
            }
            
            while let _ = try await group.next() {
                if nextIndex < total {
                    let item = items[nextIndex]
                    group.addTask {
                        try await attemptDownload(item)
                    }
                    nextIndex += 1
                }
            }
        }
    }
    
    private static func attemptDownload(_ item: DownloadItem) async throws {
        do {
            try await SingleFileDownloader.download(url: item.url, destination: item.destination)
        } catch {
            guard let fallback = item.fallbackURL else {
                throw error
            }
            try? FileManager.default.removeItem(at: item.destination)
            try await SingleFileDownloader.download(url: fallback, destination: item.destination)
        }
    }
}

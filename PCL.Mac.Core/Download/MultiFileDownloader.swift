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
    public static func download(
        items: [DownloadItem],
        concurrentLimit: Int,
        replaceMethod: ReplaceMethod = .skip
    ) async throws {
        guard !items.isEmpty else { return }
        if concurrentLimit == 1 {
            for item in items {
                try await attemptDownload(item, replaceMethod)
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
                    try await attemptDownload(item, replaceMethod)
                }
                nextIndex += 1
            }
            
            while let _ = try await group.next() {
                if nextIndex < total {
                    let item = items[nextIndex]
                    group.addTask {
                        try await attemptDownload(item, replaceMethod)
                    }
                    nextIndex += 1
                }
            }
        }
    }
    
    private static func attemptDownload(_ item: DownloadItem, _ replaceMethod: ReplaceMethod) async throws {
        if FileManager.default.fileExists(atPath: item.destination.path) && replaceMethod == .throw {
            throw MyLocalizedError(reason: "\(item.destination.lastPathComponent) 已存在。")
        }
        do {
            try await SingleFileDownloader.download(url: item.url, destination: item.destination, replaceMethod: replaceMethod)
        } catch {
            guard let fallback = item.fallbackURL else {
                throw error
            }
            try await SingleFileDownloader.download(url: fallback, destination: item.destination, replaceMethod: .replace)
        }
    }
}

public enum ReplaceMethod {
    case skip, replace, `throw`
}

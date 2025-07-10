//
//  NetworkSpeedMonitor.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/25.
//

import Foundation
import Combine

class NetworkSpeedMonitor: NSObject, ObservableObject, URLSessionDataDelegate, URLSessionTaskDelegate {
    @Published var uploadSpeed: Double = 0 // byte/s
    @Published var downloadSpeed: Double = 0 // byte/s
    
    private var _session: URLSession?
    var session: URLSession {
        get {
            if _session == nil {
                _session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            }
            
            return _session!
        }
    }

    private var lastUploadBytes: Int64 = 0
    private var lastDownloadBytes: Int64 = 0
    private var lastUploadTime: Date = Date()
    private var lastDownloadTime: Date = Date()

    // 上传进度
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let now = Date()
        let interval = now.timeIntervalSince(lastUploadTime)
        if interval > 0 {
            let bytesDelta = totalBytesSent - lastUploadBytes
            uploadSpeed = Double(bytesDelta) / interval
            lastUploadBytes = totalBytesSent
            lastUploadTime = now
        }
    }

    // 下载进度
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let now = Date()
        let interval = now.timeIntervalSince(lastDownloadTime)
        print(data.count)
        if interval > 0 {
            let bytesDelta = Int64(data.count)
            downloadSpeed = Double(bytesDelta) / interval
            lastDownloadTime = now
        }
    }
}

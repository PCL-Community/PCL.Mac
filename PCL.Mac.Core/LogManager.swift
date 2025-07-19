//
//  LogManager.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/19.
//

import Foundation
import SwiftUI

class LogLine: Identifiable {
    let id: UUID = UUID()
    let string: String
    
    init(_ string: String) {
        self.string = string
    }
}

final class LogStore {
    let dateFormatter = DateFormatter()
    static let shared = LogStore()
    private var logs: [String] = []
    var logLines: [LogLine] = []
    private let maxCapacity = 10_000
    private let writeImmediately = true
    
    private let queue = DispatchQueue(label: "io.github.pcl-community.LogStoreQueue")

    private init() {
        dateFormatter.dateFormat = "[yyyy-MM-dd] [HH:mm:ss.SSS]"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
    }
    
    func append(_ message: String, _ level: String, _ caller: String) {
        appendRaw(
            "\(dateFormatter.string(from: Date())) [\(level)] \(caller): \(message)",
            LogLine("[\(level)] \(caller): \(message)")
        )
    }
    
    func appendRaw(_ message: String, _ line: LogLine? = nil, write: Bool = true) {
        queue.async {
            if self.logs.count >= self.maxCapacity {
                self.logs.removeFirst(1000)
            }
            if self.logLines.count >= 200 {
                self.logLines.removeFirst(100)
            }
            self.logs.append(message)
            if SharedConstants.shared.isDevelopment {
                self.logLines.append(line ?? LogLine(message))
            }
            if self.writeImmediately && write {
                self.appendToDisk(message + "\n")
            }
            print(message)
        }
    }
    
    func appendToDisk(_ content: String, _ callback: ((Bool) -> Void)? = nil) {
        do {
            try FileManager.writeLog(content)
            callback?(true)
        } catch {
            err("日志保存失败: \(error.localizedDescription)")
            callback?(false)
        }
    }
    
    func clear() {
        try? FileManager.default.removeItem(at: SharedConstants.shared.applicationLogUrl)
    }
    
    func save() {
        if !writeImmediately {
            queue.async {
                let allLogs = self.logs.joined(separator: "\n")
                self.appendToDisk(allLogs) { isSuccess in
                    if isSuccess {
                        log("日志保存成功")
                    }
                    log("已触发进程终止")
                    DispatchQueue.main.async {
                        NSApp.reply(toApplicationShouldTerminate: true)
                    }
                }
            }
        }
    }
}

public struct LogManager {
    public static func log(_ message: Any, file: String = #file, line: Int = #line) {
        LogStore.shared.append(String(describing: message), "INFO", file.split(separator: "/").last! + ":" + String(line))
    }

    public static func warn(_ message: Any, file: String = #file, line: Int = #line) {
        LogStore.shared.append(String(describing: message), "WARN", file.split(separator: "/").last! + ":" + String(line))
    }

    public static func err(_ message: Any, file: String = #file, line: Int = #line) {
        LogStore.shared.append(String(describing: message), "ERROR", file.split(separator: "/").last! + ":" + String(line))
    }

    public static func debug(_ message: Any, file: String = #file, line: Int = #line) {
        LogStore.shared.append(String(describing: message), "DEBUG", file.split(separator: "/").last! + ":" + String(line))
    }

    public static func raw(_ message: Any) {
        LogStore.shared.appendRaw(String(describing: message), write: false)
    }
}

public func log(_ message: Any, file: String = #file, line: Int = #line) { LogManager.log(message, file: file, line: line) }
public func warn(_ message: Any, file: String = #file, line: Int = #line) { LogManager.warn(message, file: file, line: line) }
public func err(_ message: Any, file: String = #file, line: Int = #line) { LogManager.err(message, file: file, line: line) }
public func debug(_ message: Any, file: String = #file, line: Int = #line) { LogManager.debug(message, file: file, line: line) }
public func raw(_ message: Any, file: String = #file, line: Int = #line) { LogManager.raw(message) }


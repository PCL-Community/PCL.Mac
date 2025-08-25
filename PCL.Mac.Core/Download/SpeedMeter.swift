//
//  SpeedMeter.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/24.
//

import Foundation

@MainActor
final class SpeedMeter: ObservableObject {
    public static let shared: SpeedMeter = .init()
    
    @Published public private(set) var downloadSpeed: Int64 = 0
    
    private let counter = CounterActor()
    private var tickerTask: Task<Void, Never>?
    
    private init() {
        guard tickerTask == nil else { return }
        tickerTask = Task(priority: .background) {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                let intervalBytes = await counter.takeInterval()
                self.downloadSpeed = intervalBytes
            }
        }
    }
    
    public func addByte() async {
        await counter.add(1)
    }
    
    public func addBytes(_ n: Int) async {
        guard n > 0 else { return }
        await counter.add(Int64(n))
    }
    
    deinit {
        tickerTask?.cancel()
        tickerTask = nil
    }
}

actor CounterActor {
    private var intervalBytes: Int64 = 0
    
    func add(_ n: Int64) {
        intervalBytes &+= n
    }
    
    func takeInterval() -> Int64 {
        let v = intervalBytes
        intervalBytes = 0
        return v
    }
}

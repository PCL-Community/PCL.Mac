//
//  NetworkTest.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/3.
//

import Foundation
import Network

public class NetworkTest {
    public static let shared = NetworkTest()
    private let monitor = NWPathMonitor()
    
    public func hasNetworkConnection(timeout: TimeInterval = 2.0) -> Bool {
        let monitor = NWPathMonitor()
        let group = DispatchGroup()
        var hasConnection: Bool = false

        group.enter()
        monitor.pathUpdateHandler = { path in
            hasConnection = (path.status == .satisfied)
            group.leave()
            monitor.cancel()
        }
        monitor.start(queue: DispatchQueue.global(qos: .userInitiated))

        let waitResult = group.wait(timeout: .now() + timeout)
        if waitResult == .timedOut {
            monitor.cancel()
        }
        return hasConnection
    }
}

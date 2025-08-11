//
//  LaunchOptions.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/13.
//

import Foundation

public class LaunchOptions {
    public var javaPath: URL!
    public var isDemo: Bool = false
    public var skipResourceCheck: Bool = false
    public var playerName: String = ""
    public var uuid: UUID = .init()
    public var accessToken: String = ""
    public var account: AnyAccount?
    public var yggdrasilArguments: [String] = []
    
    public init() {}
}

//
//  Constants.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/5/20.
//

import Foundation

public struct SharedConstants {
    public static let shared = SharedConstants()
    
    public let applicationContentsUrl: URL
    public let applicationResourcesUrl: URL
    public let applicationLogUrl: URL
    public let applicationSupportUrl: URL = .applicationSupportDirectory.appending(path: "PCL-Mac")
    public let applicationTemperatureUrl: URL
    
    public let dateFormatter = DateFormatter()
    
    public let isDevelopment: Bool
    public let branch: String
    
    private init() {
        self.applicationContentsUrl = Bundle.main.bundleURL.appending(path: "Contents")
        self.applicationResourcesUrl = self.applicationContentsUrl.appending(path: "Resources")
        self.applicationLogUrl = applicationSupportUrl.appending(path: "Logs").appending(path: "app.log")
        self.applicationTemperatureUrl = applicationSupportUrl.appending(path: "Temp")
        
        self.dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        self.dateFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        
        self.isDevelopment = (Bundle.main.object(forInfoDictionaryKey: "IS_DEVELOPMENT") as! String) == "false" ? false : true
        let branch = Bundle.main.object(forInfoDictionaryKey: "BRANCH") as! String
        self.branch = branch.isEmpty ? "本地构建" : branch
    }
}

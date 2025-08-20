//
//  DownloadSourceManager.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/8/20.
//

import Foundation

public class DownloadSourceManager {
    public static let official: OfficialDownloadSource = .init()
    public static let bmclapi: BMCLAPIDownloadSource = .init()
    
    public static var current: any DownloadSource = bmclapi
}

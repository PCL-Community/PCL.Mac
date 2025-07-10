//
//  ThemeDownloader.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/7.
//

import Foundation
import Alamofire
import ZIPFoundation

public class ThemeDownloader {
    public static func getThemeList() async -> [Theme] {
        if let data = try? await AF.request("https://gitee.com/yizhimcqiu/pcl-mac-themes/raw/main/index.json")
            .serializingResponse(using: .data).value,
           let index = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let themes = index["themes"] as? [String] {
            return themes
                .map { Theme(rawValue: $0)! }
        }
        return []
    }
    
    public static func downloadTheme(_ theme: Theme) async {
        let saveUrl = SharedConstants.shared.applicationSupportUrl.appending(path: "Themes").appending(path: theme.rawValue)
        let zipUrl = saveUrl.appending(path: "zipped.zip")
        guard let data = try? await AF.request("https://gitee.com/yizhimcqiu/pcl-mac-themes/raw/main/\(theme.rawValue).zip")
            .serializingResponse(using: .data)
            .value else {
            err("无法下载主题 \(theme.rawValue)")
            return
        }
        
        do {
            if FileManager.default.fileExists(atPath: saveUrl.path) {
                try FileManager.default.removeItem(at: saveUrl)
            }
            
            try FileManager.default.createDirectory(at: zipUrl.parent(), withIntermediateDirectories: true, attributes: nil)
            if FileManager.default.fileExists(atPath: zipUrl.path) {
                try FileManager.default.removeItem(at: zipUrl)
            }
            FileManager.default.createFile(atPath: zipUrl.path, contents: data)
            try FileManager.default.unzipItem(at: zipUrl, to: saveUrl)
            try? FileManager.default.removeItem(at: zipUrl)
            log("下载主题 \(theme.rawValue) 成功")
        } catch {
            err("无法解压文件: \(error.localizedDescription)")
        }
    }
}

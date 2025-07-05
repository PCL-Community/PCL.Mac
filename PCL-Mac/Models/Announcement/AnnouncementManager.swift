//
//  AnnouncementManager.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/7/5.
//

import Foundation
import Alamofire
import SwiftyJSON

public class AnnouncementManager: ObservableObject {
    private static let root: URL = URL(string: "https://gitee.com/yizhimcqiu/pcl-mac-announcements/raw/main")!
    public static let shared: AnnouncementManager = .init()
    
    @Published var latest: Announcement? = nil
    
    private init() {
        AF.request(AnnouncementManager.root.appending(path: "latest.json"))
            .responseData { response in
                guard let data = response.data else {
                    err("无法获取数据")
                    return
                }
                
                let latest = try! JSON(data: data)
                
                AF.request(AnnouncementManager.root.appending(path: latest["path"].stringValue))
                    .responseData { response in
                        guard let data = response.data else {
                            err("无法获取数据")
                            return
                        }
                        
                        self.latest = .init(try! JSON(data: data))
                    }
            }
    }
}

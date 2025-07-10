//
//  AnnouncementManager.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/5.
//

import Foundation
import Alamofire
import SwiftyJSON

public class AnnouncementManager: ObservableObject {
    private static let root: URL = URL(string: "https://gitee.com/yizhimcqiu/pcl-mac-announcements/raw/main/announcements")!
    public static let shared: AnnouncementManager = .init()
    
    @Published var latest: Announcement? = nil
    @Published var history: [Announcement] = []
    
    public func loadHistory() {
        history.removeAll()
        AF.request(AnnouncementManager.root.appending(path: "latest.json"))
            .responseData { response in
                let latestNumber: Int
                do {
                    latestNumber = try JSON(data: response.data!)["number"].intValue
                } catch {
                    err("无法解析公告 JSON: \(error.localizedDescription)")
                    return
                }
                
                Task {
                    for i in stride(from: latestNumber, through: max(latestNumber - 9, 0), by: -1) {
                        let data: Data
                        do {
                            data = try await AF.request(AnnouncementManager.root.appending(path: "history").appending(path: "\(i).json"))
                                .serializingResponse(using: .data).value
                        } catch {
                            err("无法发送请求: \(error.localizedDescription)")
                            continue
                        }
                        
                        await MainActor.run {
                            do {
                                self.history.append(.init(try JSON(data: data)))
                            } catch {
                                err("无法解析公告 JSON: \(error.localizedDescription)")
                                return
                            }
                        }
                    }
                }
            }
    }
    
    private init() {
        AF.request(AnnouncementManager.root.appending(path: "latest.json"))
            .responseData { response in
                let latest: JSON
                do {
                    latest = try JSON(data: response.data!)
                } catch {
                    err("无法解析公告 JSON: \(error.localizedDescription)")
                    return
                }
                
                AF.request(AnnouncementManager.root.appending(path: latest["path"].stringValue))
                    .responseData { response in
                        do {
                            self.latest = .init(try JSON(data: response.data!))
                        } catch {
                            err("无法解析公告 JSON: \(error.localizedDescription)")
                            return
                        }
                    }
            }
    }
}

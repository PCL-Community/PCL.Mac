//
//  MsLogin.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/6/1.
//

import Foundation
import SwiftUI
import Alamofire
import UserNotifications

public struct DeviceAuthResponse: Codable {
    let deviceCode: String
    let expiresIn: Int
    let interval: Int
    let message: String
    let userCode: String
    let verificationUri: String

    enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case expiresIn = "expires_in"
        case interval
        case message
        case userCode = "user_code"
        case verificationUri = "verification_uri"
    }
}

public class MsLogin {
    // MARK: 获取代码对
    public static func getDeviceCode() async -> DeviceAuthResponse? {
        if let data = try? await AF.request(
            "https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode",
            method: .post,
            parameters: [
                "client_id": Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as! String,
                "scope": "XboxLive.signin offline_access"
            ],
            encoder: URLEncodedFormParameterEncoder.default
        ).serializingResponse(using: .data).value,
           let authResponse = try? JSONDecoder().decode(DeviceAuthResponse.self, from: data) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(authResponse.userCode, forType: .string)
            NSWorkspace.shared.open(URL(string: authResponse.verificationUri)!)
            UNUserNotificationCenter.current().setNotificationCategories([])
            
            let content = UNMutableNotificationContent()
            content.title = "登录"
            content.body = "请将剪切板中的内容粘贴到输入框中"
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil // 立即触发
            )
            try? await UNUserNotificationCenter.current().add(request)
            return authResponse
        }
        return nil
    }
    
    // MARK: 轮询获取 Access Token
    public static func getAccessToken(_ deviceAuthResponse: DeviceAuthResponse) async -> String? {
        return await withCheckedContinuation { continuation in
            let queue = DispatchQueue(label: "io.pcl-community.timer")
            let timer = DispatchSource.makeTimerSource(queue: queue)
            let interval = Double(deviceAuthResponse.interval)
            var requestCount = 0
            let totalRequests = Int(Double(deviceAuthResponse.expiresIn) / interval)
            var isFinished = false

            func finish(_ token: String?) {
                if !isFinished {
                    isFinished = true
                    timer.cancel()
                    continuation.resume(returning: token)
                }
            }

            timer.setEventHandler {
                if isFinished { return }
                requestCount += 1
                
                Task {
                    if let data = try? await AF.request(
                        "https://login.microsoftonline.com/consumers/oauth2/v2.0/token",
                        method: .post,
                        parameters: [
                            "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                            "client_id": Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as! String,
                            "device_code": deviceAuthResponse.deviceCode
                        ]
                    ).serializingResponse(using: .data).value,
                       let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let accessToken = dict["access_token"] as? String,
                       let refreshToken = dict["refresh_token"] as? String {
                        AppSettings.shared.refreshToken = refreshToken
                        finish(accessToken)
                        return
                    }
                }
                
                debug("轮询第 \(requestCount) / \(totalRequests) 次")
                if requestCount >= totalRequests {
                    debug("无结果")
                    finish(nil)
                }
            }
            timer.schedule(deadline: .now(), repeating: interval)
            timer.resume()
        }
    }
    
    // MARK: 刷新 Access Token
    public static func refreshAccessToken(_ refreshToken: String) async -> String? {
        if let data = try? await AF.request(
            "https://login.microsoftonline.com/consumers/oauth2/v2.0/token",
            method: .post,
            parameters: [
                "client_id": Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as! String,
                "refresh_token": refreshToken,
                "grant_type": "refresh_token",
                "scope": "XboxLive.signin offline_access"
            ]
        ).serializingResponse(using: .data).value,
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let accessToken = dict["access_token"] as? String,
           let refreshToken = dict["refresh_token"] as? String {
            AppSettings.shared.refreshToken = refreshToken
            AppSettings.shared.lastRefreshToken = Date()
            return accessToken
        }
        
        return nil
    }
    
    // MARK: 获取 Minecraft Access Token
    public static func getMinecraftAccessToken(_ accessToken: String) async -> String? {
        if let data = try? await AF.request(
            "https://user.auth.xboxlive.com/user/authenticate",
            method: .post,
            parameters: [
                "Properties": [
                    "AuthMethod": "RPS",
                    "SiteName": "user.auth.xboxlive.com",
                    "RpsTicket": "d=\(accessToken)"
                ],
                "RelyingParty": "http://auth.xboxlive.com",
                "TokenType": "JWT"
            ],
            encoding: JSONEncoding.default
        ).serializingResponse(using: .data).value,
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = dict["Token"] as? String,
           let uhs = (dict["DisplayClaims"] as? [String : [[String : String]]])?["xui"]?.first?["uhs"] {
            if let data = try? await AF.request(
                "https://xsts.auth.xboxlive.com/xsts/authorize",
                method: .post,
                parameters: [
                    "Properties": [
                        "SandboxId": "RETAIL",
                        "UserTokens": [
                            token
                        ]
                    ],
                    "RelyingParty": "rp://api.minecraftservices.com/",
                    "TokenType": "JWT"
                ],
                encoding: JSONEncoding.default
            ).serializingResponse(using: .data).value,
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = dict["Token"] as? String {
                if let data = try? await AF.request(
                    "https://api.minecraftservices.com/authentication/login_with_xbox",
                    method: .post,
                    parameters: [
                        "identityToken": "XBL3.0 x=\(uhs);\(token)"
                    ],
                    encoding: JSONEncoding.default
                ).serializingResponse(using: .data).value,
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let accessToken = dict["access_token"] as? String {
                    return accessToken
                } else {
                    err("无法获取 Minecraft 访问令牌")
                }
            } else {
                err("XSTS 身份验证失败")
            }
        } else {
            err("Xbox Live 身份验证失败")
        }
        return nil
    }
    
    /// 数据直接存到 LocalStorage 里，不返回
    public static func login() async {
        var accessToken: String!
        
        if let refreshToken = AppSettings.shared.refreshToken {
            if abs(Date().timeIntervalSince(AppSettings.shared.lastRefreshToken)) < 86400 {
                log("无需刷新 Access Token")
                return
            }
            accessToken = await refreshAccessToken(refreshToken)
        } else {
            if let deviceCode = await getDeviceCode() {
                accessToken = await getAccessToken(deviceCode)
            } else {
                err("无法获取设备码")
            }
        }
        
        AppSettings.shared.accessToken = await getMinecraftAccessToken(accessToken)
        log("已刷新 Access Token")
    }
}

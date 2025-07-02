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
import SwiftyJSON

public class AuthToken: ObservableObject {
    @Published fileprivate(set) var minecraftAccessToken: String?
    @Published private(set) var accessToken: String
    @Published private(set) var refreshToken: String
    
    init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

public struct DeviceAuthResponse {
    let deviceCode: String
    let expiresIn: Int
    let interval: Int
    let userCode: String
    let verificationUri: String
    
    init(_ json: JSON) {
        self.deviceCode = json["device_code"].stringValue
        self.expiresIn = json["expires_in"].intValue
        self.interval = json["interval"].intValue
        self.userCode = json["user_code"].stringValue
        self.verificationUri = json["verification_uri"].stringValue
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
           let json = try? JSON(data: data) {
            let authResponse = DeviceAuthResponse(json)
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
            await ContentView.setPopup(.init("登录 Minecraft", """
登录网页将自动开启，请在网页中输入 \(authResponse.userCode)（已自动复制）。

如果网络环境不佳，网页可能一直加载不出来，届时请使用使用加速器或 VPN 以改善网络环境。
你也可以用其他设备打开 \(authResponse.verificationUri) 并输入上述代码。
""", [.Ok]))
            
            return authResponse
        }
        return nil
    }
    
    // MARK: 轮询获取 Access Token
    public static func getAccessToken(_ deviceAuthResponse: DeviceAuthResponse) async -> AuthToken? {
        return await withCheckedContinuation { continuation in
            let queue = DispatchQueue(label: "io.pcl-community.timer")
            let timer = DispatchSource.makeTimerSource(queue: queue)
            let interval = Double(deviceAuthResponse.interval)
            var requestCount = 0
            let totalRequests = Int(Double(deviceAuthResponse.expiresIn) / interval)
            var isFinished = false

            func finish(_ authToken: AuthToken?) {
                if !isFinished {
                    isFinished = true
                    timer.cancel()
                    continuation.resume(returning: authToken)
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
                       let json = try? JSON(data: data),
                       let accessToken = json["access_token"].string,
                       let refreshToken = json["refresh_token"].string {
                        finish(.init(accessToken: accessToken, refreshToken: refreshToken))
                        return
                    }
                }
                
                debug("轮询第 \(requestCount) / \(totalRequests) 次")
                if requestCount >= totalRequests {
                    err("轮询已结束，但没有获取到 Access Token")
                    finish(nil)
                }
            }
            timer.schedule(deadline: .now(), repeating: interval)
            timer.resume()
        }
    }
    
    // MARK: 刷新 Access Token
    public static func refreshAccessToken(_ refreshToken: String) async -> AuthToken? {
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
           let json = try? JSON(data: data),
           let accessToken = json["access_token"].string,
           let refreshToken = json["refresh_token"].string {
            return .init(accessToken: accessToken, refreshToken: refreshToken)
        }
        
        return nil
    }
    
    // MARK: 获取 Minecraft Access Token
    public static func getMinecraftAccessToken(id: UUID? = nil, _ accessToken: String) async -> String? {
        if let id = id,
           let accessToken = AccessTokenStorage.shared.getTokenInfo(for: id)?.accessToken {
            return accessToken
        }
        
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
           let json = try? JSON(data: data),
           let token = json["Token"].string,
           let uhs = json["DisplayClaims"]["xui"].array?.first?["uhs"].string {
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
               let json = try? JSON(data: data),
               let token = json["Token"].string {
                if let data = try? await AF.request(
                    "https://api.minecraftservices.com/authentication/login_with_xbox",
                    method: .post,
                    parameters: [
                        "identityToken": "XBL3.0 x=\(uhs);\(token)"
                    ],
                    encoding: JSONEncoding.default
                ).serializingResponse(using: .data).value,
                   let json = try? JSON(data: data),
                   let accessToken = json["access_token"].string {
                    if let id = id {
                        AccessTokenStorage.shared.add(id: id, accessToken: accessToken, expiriesIn: json["expires_in"].intValue)
                    }
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
    
    // MARK: 检测是否拥有 Minecraft
    public static func hasMinecraftGame(_ authToken: AuthToken) async -> Bool {
        guard let accessToken = authToken.minecraftAccessToken else { return false }
        
        if let data = try? await AF.request(
            "https://api.minecraftservices.com/entitlements/mcstore",
            method: .get,
            encoding: JSONEncoding.default,
            headers: .init(
                [.authorization("Bearer \(accessToken)")]
            )
        ).serializingResponse(using: .data).value,
           let json = try? JSON(data: data) {
            return json["items"].arrayValue.contains(where: { $0["name"].stringValue == "product_minecraft" })
        }
        
        return false
    }
    
    /// 登录并获取 Access Token
    public static func signIn() async -> AuthToken? {
        log("正在获取设备码")
        guard let deviceCode = await getDeviceCode() else {
            err("无法获取设备码")
            return nil
        }
        
        guard let authToken = await getAccessToken(deviceCode) else { return nil }
        authToken.minecraftAccessToken = await getMinecraftAccessToken(authToken.accessToken)
        return authToken
    }
}

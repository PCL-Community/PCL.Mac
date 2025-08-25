//
//  Requests.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/11.
//

import Foundation
import SwiftyJSON

public protocol URLConvertible {
    var url: URL { get }
}

extension URL: URLConvertible {
    public var url: URL { self }
}

extension String: URLConvertible {
    public var url: URL { URL(string: self)! }
}

public enum EncodeMethod {
    case json
    case urlEncoded
}

public struct Response {
    public let data: Data?
    public let json: JSON?
    public let error: Error?
    
    public func getDataOrThrow() throws -> Data {
        guard let data = self.data else {
            throw self.error ?? NSError(domain: "data 为空", code: -1)
        }
        
        return data
    }
    
    public func getJSONOrThrow() throws -> JSON {
        return try JSON(data: getDataOrThrow())
    }
}

public class Requests {
    public static func request(
        url: URL,
        method: String = "GET",
        headers: [String: String]? = nil,
        body: [String: Any]? = nil,
        encodeMethod: EncodeMethod = .json,
        ignoredFailureStatusCodes: [Int]
    ) async -> Response {
        do {
            var request = URLRequest(url: url)
            request.httpMethod = method
            
            headers?.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            if let body = body {
                switch encodeMethod {
                case .json:
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
                case .urlEncoded:
                    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    if method == "GET" {
                        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
                        components.queryItems = body.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
                        request.url = components.url
                    } else {
                        let query = body.map { key, value in
                            "\(key)=\(String(describing: value))"
                        }.joined(separator: "&")
                        request.httpBody = query.data(using: .utf8)
                    }
                }
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            if let response = response as? HTTPURLResponse, response.statusCode != 200 && !ignoredFailureStatusCodes.contains(response.statusCode) {
                debug("\(url.absoluteString) 返回了 \(response.statusCode): \(String(data: data, encoding: .utf8) ?? "(empty)")")
            }
            let json = try? JSON(data: data)
            return Response(data: data, json: json, error: nil)
        } catch let error as URLError where error.code == .cancelled {
            return Response(data: nil, json: nil, error: nil)
        } catch {
            err("在发送请求时发生错误: \(error)")
            return Response(data: nil, json: nil, error: error)
        }
    }

    public static func get(
        _ url: URLConvertible,
        headers: [String: String]? = nil,
        body: [String: Any]? = nil,
        encodeMethod: EncodeMethod = .urlEncoded,
        ignoredFailureStatusCodes: [Int] = []
    ) async -> Response {
        return await request(url: url.url, method: "GET", headers: headers, body: body, encodeMethod: encodeMethod, ignoredFailureStatusCodes: ignoredFailureStatusCodes)
    }

    public static func post(
        _ url: URLConvertible,
        headers: [String: String]? = nil,
        body: [String: Any]? = nil,
        encodeMethod: EncodeMethod = .json,
        ignoredFailureStatusCodes: [Int] = []
    ) async -> Response {
        return await request(url: url.url, method: "POST", headers: headers, body: body, encodeMethod: encodeMethod, ignoredFailureStatusCodes: ignoredFailureStatusCodes)
    }
}

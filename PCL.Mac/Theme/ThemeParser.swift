//
//  ThemeParser.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/5/25.
//

import SwiftUI
import SwiftyJSON

public class ThemeParser {
    public static let shared: ThemeParser = .init()
    
    public func fromJSON(_ json: JSON) -> Theme? {
        return nil
    }
    
    public func parseColor(_ str: String) -> Color? {
        if str.starts(with: "#") { // RGB / ARGB 格式
            let hexStr = String(str.dropFirst())
            if hexStr.count == 6, let rgbInt = UInt(hexStr, radix: 16) { // RGB
                return Color(hex: rgbInt)
            } else if hexStr.count == 8,
                      let argbInt = UInt(hexStr, radix: 16) { // ARGB
                let alpha = Double((argbInt >> 24) & 0xFF) / 255.0
                let rgb = argbInt & 0xFFFFFF
                return Color(hex: rgb, alpha: alpha)
            }
        } else if let match = str.wholeMatch(of: /hsl\(\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*\)/),
                  let h = Double(match.1), let s = Double(match.2), let l = Double(match.3) {
            return Color(h2: h, s2: s, l2: l)
        }
        return nil
    }
    
    public func parseGradient(_ json: JSON) -> AnyShapeStyle? {
        if json["type"].stringValue == "linearGradient" {
            guard let startPointArray = json["startPoint"].array,
                  let endPointArray = json["endPoint"].array,
                  let colorsArray = json["colors"].array else {
                return nil
            }
            
            let startPoint = UnitPoint(x: startPointArray[0].doubleValue, y: startPointArray[1].doubleValue)
            let endPoint = UnitPoint(x: endPointArray[0].doubleValue, y: endPointArray[1].doubleValue)
            
            if colorsArray[0].type == .string { // 不带 location 的均匀分布 color
                return AnyShapeStyle(
                    LinearGradient(
                        gradient: Gradient(colors: colorsArray.map { $0.stringValue }.compactMap(parseColor(_:))),
                        startPoint: startPoint,
                        endPoint: endPoint
                    )
                )
            } else if colorsArray[0].type == .dictionary { // 带 location 的 Stop
                let stops: [Gradient.Stop] = colorsArray.compactMap { stop in
                    guard let color = parseColor(stop["color"].stringValue) else { return nil }
                    return Gradient.Stop(color: color, location: stop["location"].doubleValue)
                }
                return AnyShapeStyle(
                    LinearGradient(
                        gradient: Gradient(stops: stops),
                        startPoint: startPoint,
                        endPoint: endPoint
                    )
                )
            }
        }
        
        return nil
    }
    
    private init() {}
}

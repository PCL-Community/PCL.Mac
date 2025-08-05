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
    
    public func fromJSON(_ json: JSON) -> Theme {
        let id = json["id"].stringValue
        let name = json["name"].stringValue
        
        let accentColor = parseColor(json["accentColor"])
        let mainStyle = parseStyle(json["mainStyle"])
        let backgroundStyle = parseStyle(json["backgroundStyle"])
        let textStyle = parseStyle(json["textStyle"].exists() ? json["textStyle"] : json["titleStyle"])
        
        return Theme(id: id, accentColor: accentColor, mainStyle: mainStyle, backgroundStyle: backgroundStyle, textStyle: textStyle)
    }
    
    public func parseStyle(_ json: JSON) -> AnyShapeStyle {
        let type = json["type"].stringValue
        
        switch type {
        case "color", "":
            return AnyShapeStyle(parseColor(json))
        case "linearGradient":
            if let gradient = parseGradient(json) { return AnyShapeStyle(gradient) }
        default:
            let _: Any? = nil
        }
        
        return AnyShapeStyle(Color(hex: 0x000000))
    }
    
    public func parseColor(_ json: JSON) -> Color {
        let str: String
        if json.type == .string {
            str = json.stringValue
        } else if json["darkColor"].exists() && !ColorConstants.isLight {
            str = json["darkColor"].stringValue
        } else {
            str = json["color"].stringValue
        }
        
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
        return Color(hex: 0x000000)
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
                        gradient: Gradient(colors: colorsArray.map(parseColor(_:))),
                        startPoint: startPoint,
                        endPoint: endPoint
                    )
                )
            } else if colorsArray[0].type == .dictionary { // 带 location 的 Stop
                let stops: [Gradient.Stop] = colorsArray.map { stop in
                    return Gradient.Stop(color: parseColor(stop), location: stop["location"].doubleValue)
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

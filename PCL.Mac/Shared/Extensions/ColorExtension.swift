//
//  ColorExtension.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/17.
//

import SwiftUI
import AppKit

class ColorConstants {
    public static var colorScheme: ColorSchemeOption = .light
    
    public static var isLight: Bool {
        if colorScheme != .system {
            return colorScheme == .light
        }
        let appearance = NSApp.effectiveAppearance
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return !isDark
    }
    
    public static var L1: Double { isLight ? 25 : 96 }
    public static var L2: Double { isLight ? 45 : 75 }
    public static var L3: Double { isLight ? 55 : 60 }
    public static var L4: Double { isLight ? 65 : 65 }
    public static var L5: Double { isLight ? 80 : 45 }
    public static var L6: Double { isLight ? 91 : 25 }
    public static var L7: Double { isLight ? 95 : 22 }
    public static var L8: Double { isLight ? 97 : 20 }
    
    public static var G1: Double { isLight ? 100 : 15 }
    public static var G2: Double { isLight ? 98 : 20 }
    public static var G3: Double { isLight ? 0 : 100 }
    
    public static var Sa0: Double { 1 }
    public static var Sa1: Double { isLight ? 1 : 0.4 }
    
    public static var LaP: Double { isLight ? 1 : 0.75 }
    public static var LaN: Double { isLight ? 0.5 : 0.75 }
}

public extension Color {
    /// 通过 16 进制整数创建颜色（格式：0xRRGGBB）
    /// - Parameter hex: 16 进制颜色值（如 0xFF5733）
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
    
    /// 完全复刻 PCL2-CE 的 FromHSL2 算法（亮度中心修正）
    /// - Parameters:
    ///   - h: 色相 (0-360)
    ///   - s: 饱和度 (0-100)
    ///   - l: 亮度 (0-100)
    init(h2 h: Double, s2 s: Double, l2 l: Double) {
        if s == 0 {
            let v = mathByte(l * 2.55)
            self.init(.sRGB, red: v / 255.0, green: v / 255.0, blue: v / 255.0, opacity: 1.0)
        } else {
            let sH = (h + 3600000).truncatingRemainder(dividingBy: 360)
            let cent: [Double] = [
                +0.1, -0.06, -0.3,
                 -0.19, -0.15, -0.24,
                 -0.32, -0.09, +0.18,
                 +0.05, -0.12, -0.02,
                 +0.1, -0.06
            ]
            let centerF = sH / 30.0
            let intCenter = Int(floor(centerF))
            let center = 50.0 - (
                (1 - centerF + Double(intCenter)) * cent[intCenter] +
                (centerF - Double(intCenter)) * cent[intCenter + 1]
            ) * s
            var sL = l
            if sL < center {
                sL = sL / center
            } else {
                sL = 1 + (sL - center) / (100 - center)
            }
            sL = sL * 50
            // HSL → RGB，务必四舍五入并限制范围后再归一化
            let rgb = Color.hslToRgb(h: sH, s: s, l: sL)
            self.init(.sRGB, red: rgb.r / 255.0, green: rgb.g / 255.0, blue: rgb.b / 255.0, opacity: 1.0)
        }
    }
    
    /// 标准 HSL → RGB（返回四舍五入后的 0~255 分量）
    private static func hslToRgb(h: Double, s: Double, l: Double) -> (r: Double, g: Double, b: Double) {
        var r: Double = 0, g: Double = 0, b: Double = 0
        if s == 0 {
            r = mathByte(l * 2.55)
            g = r
            b = r
        } else {
            let H = h / 360
            var S = s / 100
            var L = l / 100
            S = (L < 0.5) ? (S * L + L) : (S * (1.0 - L) + L)
            L = 2 * L - S
            func hue(_ p: Double, _ q: Double, _ t: Double) -> Double {
                var t = t
                if t < 0 { t += 1 }
                if t > 1 { t -= 1 }
                if t < 0.16667 { return p + (q - p) * 6 * t }
                if t < 0.5 { return q }
                if t < 0.66667 { return p + (q - p) * (4 - t * 6) }
                return p
            }
            r = mathByte(255 * hue(L, S, H + 1.0 / 3.0))
            g = mathByte(255 * hue(L, S, H))
            b = mathByte(255 * hue(L, S, H - 1.0 / 3.0))
        }
        return (r, g, b)
    }
}

fileprivate func mathByte(_ value: Double) -> Double {
    var result = value
    if result < 0 { result = 0 }
    if result > 255 { result = 255 }
    return round(result)
}

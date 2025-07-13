//
//  ColorExtension.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/17.
//

import SwiftUI

extension Color {
    /// 通过 16 进制整数创建颜色（格式：0xRRGGBB）
    /// - Parameter hex: 16 进制颜色值（如 0xFF5733）
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    // MARK: - PCL原版颜色常量
    /// PCL原版颜色系统，严格按照PCL的颜色定义
    static let pclOriginalColor1 = Color(red: 52/255.0, green: 61/255.0, blue: 74/255.0)      // #343d4a
    static let pclOriginalColor2 = Color(red: 11/255.0, green: 91/255.0, blue: 203/255.0)     // #0b5bcb
    static let pclOriginalColor3 = Color(red: 19/255.0, green: 112/255.0, blue: 243/255.0)    // #1370f3
    static let pclOriginalColor4 = Color(red: 72/255.0, green: 144/255.0, blue: 245/255.0)    // #4890f5
    static let pclOriginalColor5 = Color(red: 150/255.0, green: 192/255.0, blue: 249/255.0)   // #96c0f9
    static let pclOriginalColor6 = Color(red: 213/255.0, green: 230/255.0, blue: 253/255.0)   // #d5e6fd
    static let pclOriginalColor7 = Color(red: 222/255.0, green: 236/255.0, blue: 253/255.0)   // #deecfd
    static let pclOriginalColor8 = Color(red: 234/255.0, green: 242/255.0, blue: 254/255.0)   // #eaf2fe
    static let pclOriginalColorBg0 = Color(red: 150/255.0, green: 192/255.0, blue: 249/255.0) // #96c0f9
    static let pclOriginalColorBg1 = Color(red: 222/255.0, green: 236/255.0, blue: 253/255.0).opacity(0.745) // #bee0eafd

    // PCL原版灰色系统
    static let pclOriginalGray1 = Color(red: 64/255.0, green: 64/255.0, blue: 64/255.0)       // #404040
    static let pclOriginalGray2 = Color(red: 115/255.0, green: 115/255.0, blue: 115/255.0)    // #737373
    static let pclOriginalGray3 = Color(red: 140/255.0, green: 140/255.0, blue: 140/255.0)    // #8c8c8c
    static let pclOriginalGray4 = Color(red: 166/255.0, green: 166/255.0, blue: 166/255.0)    // #a6a6a6
    static let pclOriginalGray5 = Color(red: 204/255.0, green: 204/255.0, blue: 204/255.0)    // #cccccc
    static let pclOriginalGray6 = Color(red: 235/255.0, green: 235/255.0, blue: 235/255.0)    // #ebebeb
    static let pclOriginalGray7 = Color(red: 240/255.0, green: 240/255.0, blue: 240/255.0)    // #f0f0f0
    static let pclOriginalGray8 = Color(red: 245/255.0, green: 245/255.0, blue: 245/255.0)    // #f5f5f5

    // PCL原版特殊颜色
    static let pclOriginalWhite = Color.white
    static let pclOriginalHalfWhite = Color.white.opacity(0.333)
    static let pclOriginalSemiWhite = Color.white.opacity(0.733)
    static let pclOriginalTransparent = Color.clear
    static let pclOriginalSemiTransparent = Color(red: 234/255.0, green: 242/255.0, blue: 254/255.0).opacity(0.004)
    static let pclOriginalBackgroundTransparentSidebar = Color(red: 241/255.0, green: 255/255.0, blue: 255/255.0).opacity(0.945)

    /// 通过 HSL 值创建颜色（严格按照PCL原版HSL算法）
    /// - Parameters:
    ///   - hue: 色调 (0-360)
    ///   - saturation: 饱和度 (0-100)
    ///   - lightness: 亮度 (0-100)
    ///   - alpha: 透明度 (0-1)
    init(hsl hue: Double, saturation: Double, lightness: Double, alpha: Double = 1.0) {
        let h = (hue + 3600000).truncatingRemainder(dividingBy: 360)
        let s = saturation / 100.0
        let l = lightness / 100.0

        let r: Double
        let g: Double
        let b: Double

        if s == 0 {
            r = l * 2.55
            g = r
            b = r
        } else {
            // PCL的HSL2算法实现
            let cent: [Double] = [
                +0.1, -0.06, -0.3,    // 0, 30, 60
                -0.19, -0.15, -0.24,  // 90, 120, 150
                -0.32, -0.09, +0.18,  // 180, 210, 240
                +0.05, -0.12, -0.02,  // 270, 300, 330
                +0.1, -0.06           // 最后两位与前两位一致
            ]

            let center = h / 30.0
            let intCenter = Int(floor(center))
            let centerAdj = 50 - (
                (1 - center + Double(intCenter)) * cent[intCenter] +
                (center - Double(intCenter)) * cent[intCenter + 1]
            ) * s * 100

            let adjustedL = l < centerAdj / 100 ?
                (l / (centerAdj / 100)) * 50 :
                (1 + (l - centerAdj / 100) / (1 - centerAdj / 100)) * 50

            // 转换为标准HSL
            let hNorm = h / 360
            let sNorm = s
            let lNorm = adjustedL / 100

            let c = (1 - abs(2 * lNorm - 1)) * sNorm
            let x = c * (1 - abs((hNorm * 6).truncatingRemainder(dividingBy: 2) - 1))
            let m = lNorm - c / 2

            let (r1, g1, b1): (Double, Double, Double)
            switch Int(hNorm * 6) {
            case 0: (r1, g1, b1) = (c, x, 0)
            case 1: (r1, g1, b1) = (x, c, 0)
            case 2: (r1, g1, b1) = (0, c, x)
            case 3: (r1, g1, b1) = (0, x, c)
            case 4: (r1, g1, b1) = (x, 0, c)
            case 5: (r1, g1, b1) = (c, 0, x)
            default: (r1, g1, b1) = (0, 0, 0)
            }

            r = (r1 + m) * 255
            g = (g1 + m) * 255
            b = (b1 + m) * 255
        }

        self.init(.sRGB,
                 red: min(max(r / 255.0, 0), 1),
                 green: min(max(g / 255.0, 0), 1),
                 blue: min(max(b / 255.0, 0), 1),
                 opacity: alpha)
    }
}

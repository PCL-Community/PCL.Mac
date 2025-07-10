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
}

//
//  Theme.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/30.
//

import SwiftUI

public enum Theme: String, CaseIterable, Codable {
    case pcl, colorful, venti
    
    /// 获取主渐变色（如标题栏）
    public func getStyle() -> some ShapeStyle {
        switch self {
        case .venti:
            return AnyShapeStyle(Color(hex: 0x23D49F))
        case .colorful:
            return AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: 0xFFAC4A),
                        Color(hex: 0xFF3769),
                        Color(hex: 0xD29CFF),
                        Color(hex: 0x8ACFEA)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .topTrailing
                )
            )
        case .pcl:
            return AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: 0x106AC4), location: 0.0),
                        .init(color: Color(hex: 0x1277DD), location: 0.5),
                        .init(color: Color(hex: 0x106AC4), location: 1.0)
                    ]),
                    startPoint: UnitPoint(x: 0.0, y: 0.0),
                    endPoint: UnitPoint(x: 1.0, y: 0.0)
                )
            )
        }
    }
    
    /// 获取副渐变色（如背景）
    public func getBackgroundStyle(colorful: Bool = true) -> some ShapeStyle {
        switch self {
        case .venti:
            return AnyShapeStyle(Color(hex: 0x23D49F, alpha: 0.7))
        case .pcl:
            if colorful {
                return AnyShapeStyle(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(hsl: 195, saturation: 68, lightness: 91), location: -0.1),
                            .init(color: Color(hsl: 210, saturation: 68, lightness: 91), location: 0.4),
                            .init(color: Color(hsl: 225, saturation: 68, lightness: 91), location: 1.1)
                        ]),
                        startPoint: UnitPoint(x: 0.9, y: 0.0),
                        endPoint: UnitPoint(x: 0.1, y: 1.0)
                    )
                )
            } else {
                // PCL原版非彩色背景：RGB(245, 245, 245)
                return AnyShapeStyle(Color(red: 245/255.0, green: 245/255.0, blue: 245/255.0))
            }
        case .colorful:
            return AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: 0xCC8A28), // 橙色
                        Color(hex: 0xDD1547), // 红色
                        Color(hex: 0xB07ADD), // 紫色
                        Color(hex: 0x68ADC8), // 蓝色
                    ]),
                    startPoint: .topLeading,
                    endPoint: .topTrailing
                )
            )
        }
    }
    
    public func getTextStyle() -> AnyShapeStyle {
        switch self {
        case .pcl:
            return AnyShapeStyle(Color.pclOriginalColor3) // PCL原版蓝色文本
        default:
            return AnyShapeStyle(getStyle())
        }
    }

    /// 获取PCL原版按钮颜色
    public func getButtonStyle(isHighlight: Bool = false, isHover: Bool = false) -> AnyShapeStyle {
        switch self {
        case .pcl:
            if isHighlight {
                return AnyShapeStyle(isHover ? Color.pclOriginalColor3 : Color.pclOriginalColor2)
            } else {
                return AnyShapeStyle(isHover ? Color.pclOriginalColor3 : Color.pclOriginalColor1)
            }
        default:
            return AnyShapeStyle(getStyle())
        }
    }

    /// 获取PCL原版卡片悬停颜色
    public func getCardHoverStyle() -> AnyShapeStyle {
        switch self {
        case .pcl:
            return AnyShapeStyle(Color.pclOriginalColor2)
        default:
            return AnyShapeStyle(getStyle())
        }
    }
    
    /// 带图片主题的标题栏视图
    public func getGradientView() -> some View {
        switch self {
        case .venti:
            return AnyView(
                HStack {
                    Spacer()
                    Image("TVentiImage1")
                        .resizable()
                        .scaledToFit()
                        .opacity(0.1)
                }
                    .background(getStyle())
            )
        case .pcl:
            // PCL原版标题栏渐变：使用精确的RGB原生值（调亮版本）
            // 最左侧：RGB(47, 115, 217)，最中间：RGB(49, 125, 243)，最右侧：RGB(47, 113, 213)
            return AnyView(
                EmptyView().background(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(red: 47/255.0, green: 115/255.0, blue: 217/255.0), location: 0.0),   // 最左侧（调亮+30）
                            .init(color: Color(red: 49/255.0, green: 125/255.0, blue: 243/255.0), location: 0.5),   // 最中间（调亮+30）
                            .init(color: Color(red: 47/255.0, green: 113/255.0, blue: 213/255.0), location: 1.0)    // 最右侧（调亮+30）
                        ]),
                        startPoint: UnitPoint(x: 0.0, y: 0.0),
                        endPoint: UnitPoint(x: 1.0, y: 0.0)
                    )
                )
            )
        default:
            return AnyView(EmptyView().background(getStyle()))
        }
    }
    
    /// 带图片主题的背景视图
    public func getBackgroundView(colorful: Bool = true) -> some View {
        switch self {
        case .venti:
            return AnyView(
                HStack {
                    Spacer()
                    Image("TVentiImage1")
                        .resizable()
                        .scaledToFit()
                        .opacity(0.1)
                }
                    .background(getBackgroundStyle(colorful: colorful))
            )
        default:
            return AnyView(EmptyView().background(getBackgroundStyle(colorful: colorful)))
        }
    }
}

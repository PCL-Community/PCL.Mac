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
    public func getBackgroundStyle() -> some ShapeStyle {
        switch self {
        case .venti:
            return AnyShapeStyle(Color(hex: 0x23D49F, alpha: 0.7))
        case .pcl:
            return AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color("BackgroundGradient0"), location: 0.0),
                        .init(color: Color("BackgroundGradient1"), location: 0.4),
                        .init(color: Color("BackgroundGradient2"), location: 1.0)
                    ]),
                    startPoint: UnitPoint(x: 0.9, y: 0.0),
                    endPoint: UnitPoint(x: 0.1, y: 1.0)
                )
            )
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
            return AnyShapeStyle(Color(hex: 0x1370F3))
        default:
            return AnyShapeStyle(getStyle())
        }
    }
    
    /// 带图片主题的标题栏视图
    public func getGradientView() -> some View {
        switch self {
        default:
            return AnyView(EmptyView().background(getStyle()))
        }
    }
    
    /// 带图片主题的背景视图
    public func getBackgroundView() -> some View {
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
                    .background(getBackgroundStyle())
            )
        default:
            return AnyView(EmptyView().background(getBackgroundStyle()))
        }
    }
}

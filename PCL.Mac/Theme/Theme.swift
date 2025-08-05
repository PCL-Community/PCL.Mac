//
//  Theme.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/30.
//

import SwiftUI
import SwiftyJSON

public class Theme: Codable, Hashable, Equatable {
    public static var pcl: Theme = {
        do {
            let url = SharedConstants.shared.applicationResourcesUrl.appending(path: "pcl.json")
            let data = try FileHandle(forReadingFrom: url).readToEnd()!
            let json = try JSON(data: data)
            return ThemeParser.shared.fromJSON(json)
        } catch {
            err("无法加载默认主题: \(error.localizedDescription)")
            return Theme(id: "pcl", mainStyle: Color(hex: 0x000000), backgroundStyle: Color(hex: 0x000000), textStyle: Color(hex: 0x000000))
        }
    }()
    
    private let id: String
    private let mainStyle: AnyShapeStyle
    private let backgroundStyle: AnyShapeStyle
    private let textStyle: AnyShapeStyle
    
    init(id: String, mainStyle: any ShapeStyle, backgroundStyle: any ShapeStyle, textStyle: any ShapeStyle) {
        self.id = id
        self.mainStyle = AnyShapeStyle(mainStyle)
        self.backgroundStyle = AnyShapeStyle(backgroundStyle)
        self.textStyle = AnyShapeStyle(textStyle)
    }
    
    /// 获取主渐变色（如标题栏）
    public func getStyle() -> AnyShapeStyle {
        return mainStyle
    }
    
    /// 获取副渐变色（如背景）
    public func getBackgroundStyle() -> AnyShapeStyle {
        return backgroundStyle
    }
    
    public func getTextStyle() -> AnyShapeStyle {
        return textStyle
    }
    
    public required init(from decoder: any Decoder) throws {
        let id = try decoder.singleValueContainer().decode(String.self)
        let url: URL
        if id == "pcl" {
            url = SharedConstants.shared.applicationResourcesUrl.appending(path: "pcl.json")
        } else {
            url = SharedConstants.shared.applicationSupportUrl.appending(path: "Themes").appending(path: "\(id).json")
        }
        
        let data = try FileHandle(forReadingFrom: url).readToEnd()!
        let json = try JSON(data: data)
        let theme = ThemeParser.shared.fromJSON(json)
        
        self.id = id
        self.mainStyle = theme.mainStyle
        self.backgroundStyle = theme.backgroundStyle
        self.textStyle = theme.textStyle
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
    
    public static func == (lhs: Theme, rhs: Theme) -> Bool { lhs.id == rhs.id }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

//
//  Theme.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/30.
//

import SwiftUI
import SwiftyJSON

public class Theme: Codable, Hashable, Equatable {
    public static var pcl: Theme = load(id: "allium")
    
    private let id: String
    private let accentColor: Color
    private let mainStyle: AnyShapeStyle
    private let backgroundStyle: AnyShapeStyle
    private let textStyle: AnyShapeStyle
    
    init(
        id: String,
        accentColor: Color,
        mainStyle: any ShapeStyle, backgroundStyle: any ShapeStyle, textStyle: any ShapeStyle
    ) {
        self.id = id
        self.accentColor = accentColor
        self.mainStyle = AnyShapeStyle(mainStyle)
        self.backgroundStyle = AnyShapeStyle(backgroundStyle)
        self.textStyle = AnyShapeStyle(textStyle)
    }
    
    /// 获取主渐变色（如标题栏）
    public func getStyle() -> AnyShapeStyle { mainStyle }
    
    /// 获取副渐变色（如背景）
    public func getBackgroundStyle() -> AnyShapeStyle { backgroundStyle }
    
    public func getTextStyle() -> AnyShapeStyle { textStyle }
    
    public func getAccentColor() -> Color { accentColor }
    
    public static func load(id: String) -> Theme {
        do {
            let internalURL: URL = SharedConstants.shared.applicationResourcesUrl.appending(path: "\(id).json")
            let externalURL: URL = SharedConstants.shared.applicationSupportUrl.appending(path: "Themes").appending(path: "\(id).json")
            
            let data = try FileHandle(forReadingFrom: FileManager.default.fileExists(atPath: internalURL.path) ? internalURL : externalURL).readToEnd()!
            let json = try JSON(data: data)
            return ThemeParser.shared.fromJSON(json)
        } catch {
            err("无法加载主题: \(error.localizedDescription)")
            return Theme(id: id, accentColor: Color(hex: 0x000000), mainStyle: Color(hex: 0x000000), backgroundStyle: Color(hex: 0x000000), textStyle: Color(hex: 0x000000))
        }
    }
    
    public required init(from decoder: any Decoder) throws {
        let id = try decoder.singleValueContainer().decode(String.self)
        let theme: Theme = .load(id: id)
        
        self.id = id
        self.accentColor = theme.accentColor
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

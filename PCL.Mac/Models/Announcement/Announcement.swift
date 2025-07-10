//
//  Announcement.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/5.
//

import SwiftUI
import SwiftyJSON

class Announcement: Identifiable {
    @ObservedObject private var dataManager: DataManager = .shared
    
    public let id: UUID = .init()
    public let title: String
    public let body: [Body]
    public let time: Date
    public let author: String
    
    init(_ json: JSON) {
        let formatter = ISO8601DateFormatter()
        self.title = json["title"].stringValue
        self.body = json["body"].arrayValue.map(Body.parse)
        self.time = formatter.date(from: json["time"].stringValue) ?? Date(timeIntervalSince1970: 0)
        self.author = json["author"].stringValue
    }
    
    func createView(showHistoryButton: Bool = false) -> some View {
        MyCardComponent(title: "公告 | \(title)") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(self.body) { body in
                    let body: Body = body
                    switch body {
                    case .text(let text, let fontSize, let color):
                        Text(text)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(color)
                            .font(.custom("PCL English", size: CGFloat(fontSize)))
                    case .image(let base64):
                        Image(nsImage: NSImage(data: Data(base64Encoded: base64, options:.ignoreUnknownCharacters)!)!)
                            .resizable()
                            .scaledToFit()
                    }
                }
                
                HStack {
                    Spacer()
                    Text("—— \(self.author) \(SharedConstants.shared.dateFormatter.string(from: self.time))")
                        .foregroundStyle(Color(hex: 0x8C8C8C))
                        .font(.custom("PCL English", size: 12))
                }
                
                if showHistoryButton {
                    MyButtonComponent(text: "历史公告") {
                        self.dataManager.router.append(.announcementHistory)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
        }
    }
}

enum Body: Identifiable {
    var id: UUID {
        return UUID()
    }
    
    case text(text: String, fontSize: Float = 14, color: Color = Color("TextColor"))
    case image(base64: String)
    
    static func parse(_ json: JSON) -> Body {
        switch json["type"].stringValue {
        case "text": .text(
            text: json["text"].stringValue,
            fontSize: json["fontSize"].float ?? 14,
            color: json["color"].exists() ? Color(hex: json["color"].uIntValue) : Color("TextColor")
        )
        case "image": .image(base64: json["base64"].stringValue)
        default: .text(text: "不受支持的格式: \(json["type"].stringValue)")
        }
    }
}

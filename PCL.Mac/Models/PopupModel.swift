//
//  PopupModel.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/10/25.
//

import Foundation

struct PopupModel {
    let type: PopupType
    let title: String
    let content: String
    let buttons: [PopupButtonModel]
    
    init(_ type: PopupType, _ title: String, _ content: String, _ buttons: [PopupButtonModel]) {
        self.title = title
        self.content = content
        self.type = type
        self.buttons = buttons
    }
}

enum PopupButtonStyle {
    case normal, accent, danger
}

struct PopupButtonModel: Identifiable, Hashable {
    let id: UUID = .init()
    let label: String
    let style: PopupButtonStyle
    
    static let close = PopupButtonModel(label: "关闭", style: .normal)
    static let ok = PopupButtonModel(label: "好的", style: .normal)
}

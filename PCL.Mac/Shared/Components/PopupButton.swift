//
//  PopupButton.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/19.
//

import SwiftUI
import AppKit

struct PopupButton: View {
    @State private var isHovered = false
    
    private let model: PopupButtonModel
    private let color: Color
    
    init(model: PopupButtonModel) {
        self.model = model
        self.color = switch model.style {
        case .normal: Color("TextColor")
        case .accent: AppSettings.shared.theme.getAccentColor()
        case .danger: Color(hex: 0xFF4C4C)
        }
    }
    
    var body: some View {
        ZStack {
            Text(model.label)
                .foregroundStyle(color)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(color)
                        .background(
                            Color(hex: 0x000000, alpha: self.isHovered ? 0.1 : 0.0)
                                .onHover { hovering in
                                    self.isHovered = hovering
                                }
                                .onTapGesture {
                                    PopupManager.shared.onClick(id: model.id)
                                }
                        )
                        .frame(height: 30)
                        .padding(.leading, -10)
                        .padding(.trailing, -10)
                        .frame(minWidth: 0, maxWidth: .infinity)
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

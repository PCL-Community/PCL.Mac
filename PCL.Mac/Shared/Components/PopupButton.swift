//
//  PopupButton.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/19.
//

import SwiftUI
import AppKit

struct PopupButton: View, Identifiable {
    @State private var isHovered = false
    
    let id = UUID()
    let text: String
    let color: Color?
    let onClick: () -> Void
    
    init(text: String, color: Color? = nil, onClick: @escaping () -> Void) {
        self.text = text
        self.color = color
        self.onClick = onClick
    }
    
    var body: some View {
        ZStack {
            Text(text)
                .foregroundStyle(color ?? Color("TextColor"))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(color ?? Color("TextColor"))
                        .background(
                            Color.pclOriginalColor7.opacity(self.isHovered ? 1.0 : 0.0)
                                .onHover { hovering in
                                    self.isHovered = hovering
                                }
                                .onTapGesture {
                                    self.onClick()
                                }
                        )
                        .frame(height: 30)
                        .padding(.leading, -10)
                        .padding(.trailing, -10)
                        .frame(minWidth: 0, maxWidth: .infinity)
                )
        }
    }
    
    static let Close = PopupButton(text: "关闭") {
        DataManager.shared.popupState = .afterCollapse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            ContentView.setPopup(nil)
        }
    }
    
    static let Ok = PopupButton(text: "好的", onClick: Close.onClick)
}

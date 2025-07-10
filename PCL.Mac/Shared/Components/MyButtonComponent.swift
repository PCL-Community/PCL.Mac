//
//  ButtonComponent.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/19.
//

import SwiftUI

struct MyButtonComponent: View {
    @ObservedObject private var dataManager: DataManager = DataManager.shared

    let text: String
    var descriptionText: String? = nil
    var foregroundStyle: (any ShapeStyle)? = nil
    let action: () -> Void

    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false

    private func getForegroundStyle() -> some ShapeStyle {
        if let foregroundStyle = self.foregroundStyle {
            return AnyShapeStyle(foregroundStyle)
        }
        return isHovered ? AnyShapeStyle(AppSettings.shared.theme.getTextStyle()) : AnyShapeStyle(Color("TextColor"))
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .stroke(self.getForegroundStyle(), lineWidth: 1.3)
            RoundedRectangle(cornerRadius: 6)
                .foregroundStyle(isHovered ? Color(hex: 0x1370F3, alpha: 0.1) : .clear)
            VStack {
                Spacer()
                Text(text)
                    .font(.custom("PCL English", size: 14))
                    .foregroundStyle(self.getForegroundStyle())
                    .padding(.leading)
                    .padding(.trailing)
                    .frame(maxWidth: .infinity)
                if let descriptionText = self.descriptionText {
                    Text(descriptionText)
                        .font(.custom("PCL English", size: 12))
                        .foregroundStyle(Color(hex: 0x9A9A9A))
                }
                Spacer()
            }
        }
        .onHover {
            isHovered = $0
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { value in
                    if isPressed {
                        action()
                    }
                    isPressed = false
                }
        )
        .scaleEffect(isPressed ? 0.85 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
    }
}


#Preview {
    MyButtonComponent(text: "测试") { }
        .padding()
        .background(Color(hex: 0xC4CEE6))
}

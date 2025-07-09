//
//  MyListItem.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/6/20.
//

import SwiftUI

struct MyListItemComponent<Content: View>: View {
    let isSelected: Bool
    let content: () -> Content
    
    @State private var isHovered: Bool = false
    
    init(isSelected: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.isSelected = isSelected
        self.content = content
    }
    
    var body: some View {
        content()
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovered ? Color(hex: 0x1370F3, alpha: 0.05) : .clear)
            )
            .animation(.easeInOut(duration: 0.2), value: self.isHovered)
            .onHover { hover in
                self.isHovered = hover
            }
            .background {
                HStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundStyle(AnyShapeStyle(AppSettings.shared.theme.getTextStyle()))
                            .frame(width: 4)
                    } else {
                        Color.clear
                    }
                    Spacer()
                }
            }
    }
}

#Preview {
    MinecraftDownloadView()
}

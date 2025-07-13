//
//  MyTextFieldComponent.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/28.
//

import SwiftUI

struct MyTextFieldComponent: View {
    @Binding var text: String
    @State private var isHovered: Bool = false
    
    let placeholder: String
    
    init(text: Binding<String>, placeholder: String = "") {
        self._text = text
        self.placeholder = placeholder
    }
    
    var body: some View {
        ZStack {
            TextField(self.placeholder, text: self.$text)
                .textFieldStyle(.plain)
                .font(.custom("PCL English", size: 14))
                .foregroundStyle(Color("TextColor"))
                .onHover() { hover in
                    self.isHovered = hover
                }
                .padding(.leading, 4)
            
            RoundedRectangle(cornerRadius: 4)
                .stroke(self.isHovered ? Color(hex: 0x4890F5) : Color(hex: 0x96C0F9), lineWidth: 1)
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.1), value: self.isHovered)
        }
        .frame(height: 27)
    }
}


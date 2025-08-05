//
//  MyTextFieldComponent.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/28.
//

import SwiftUI

struct MyTextFieldComponent: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @Binding var text: String
    @State private var isHovered: Bool = false
    @FocusState private var isFocused
    
    private let placeholder: String
    private let numberOnly: Bool
    
    init(text: Binding<String>, placeholder: String = "", numberOnly: Bool = false) {
        self._text = text
        self.placeholder = placeholder
        self.numberOnly = numberOnly
    }
    
    var body: some View {
        ZStack {
            TextField(self.placeholder, text: self.$text)
                .focused($isFocused)
                .onChange(of: text) { newValue in
                    if numberOnly {
                        text = newValue.filter { $0.isNumber }
                    }
                }
                .onSubmit {
                    isFocused = false
                }
                .textFieldStyle(.plain)
                .font(.custom("PCL English", size: 14))
                .foregroundStyle(Color("TextColor"))
                .onHover() { hover in
                    self.isHovered = hover
                }
                .padding(.leading, 5)
            
            RoundedRectangle(cornerRadius: 4)
                .stroke(AppSettings.shared.theme.getAccentColor().opacity(self.isHovered ? 1.0 : 0.5), lineWidth: 1)
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.1), value: self.isHovered)
        }
        .frame(height: 27)
    }
}


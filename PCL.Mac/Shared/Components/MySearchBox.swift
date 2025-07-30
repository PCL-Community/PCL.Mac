//
//  MySearchBox.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/29.
//

import SwiftUI

struct MySearchBox: View {
    @Binding private var query: String
    @FocusState private var isFocused: Bool
    private let placeholder: String
    private let onSubmit: (String) -> Void
    
    init(query: Binding<String>, placeholder: String, onSubmit: @escaping (String) -> Void) {
        self._query = query
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        TitlelessMyCardComponent {
            HStack {
                Image("SearchIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16)
                TextField(text: $query) {
                    Text(placeholder)
                        .foregroundStyle(Color(hex: 0x8C8C8C))
                }
                .focused($isFocused)
                .font(.custom("PCL English", size: 16))
                .textFieldStyle(.plain)
                .onChange(of: query) { newValue in
                    if newValue.count > 50 {
                        query = String(newValue.prefix(50))
                    }
                }
                .onSubmit {
                    isFocused = false
                    onSubmit(query)
                }
                Spacer()
                if !query.isEmpty {
                    Image(systemName: "xmark")
                        .bold()
                        .onTapGesture {
                            query.removeAll()
                        }
                }
            }
        }
        .frame(height: 40)
        .padding(.bottom, -7)
    }
}

#Preview {
    MySearchBox(query: .constant("a"), placeholder: "搜索 Mod 在输入框中按下 Enter 以进行搜索") { query in
        print(query)
    }
    .padding()
}

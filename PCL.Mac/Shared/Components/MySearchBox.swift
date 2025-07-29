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
    private let name: String
    private let onSubmit: (String) -> Void
    
    init(query: Binding<String>, name: String, onSubmit: @escaping (String) -> Void) {
        self._query = query
        self.name = name
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
                    Text("搜索 \(name) 在输入框中按下 Enter 以进行搜索")
                        .foregroundStyle(Color(hex: 0x8C8C8C))
                }
                .focused($isFocused)
                .font(.custom("PCL English", size: 14))
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
    }
}

#Preview {
    MySearchBox(query: .constant("a"), name: "Mod") { query in
        print(query)
    }
    .padding()
}

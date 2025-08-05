//
//  MyCompoBox.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/21.
//

import SwiftUI

struct MyComboBoxComponent<Option: Hashable, Content: View>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String
    let content: (ForEach<[Option], Option, AnyView>) -> Content

    var body: some View {
        content(
            ForEach(options, id: \.self) { option in
                AnyView(MyComboBoxItemComponent(selection: $selection, value: option, text: label(option)))
            }
        )
    }
}

struct MyComboBoxItemComponent<Option: Hashable>: View {
    @ObservedObject private var dataManager: DataManager = .shared
    
    @Binding var selection: Option
    let value: Option
    let text: String
    
    @State private var outerLength: CGFloat = 20
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 1)
                    .frame(width: outerLength)
                
                if selection == value {
                    Circle()
                        .frame(width: 10)
                }
            }
            .foregroundStyle(selection == value ? AppSettings.shared.theme.getTextStyle() : AnyShapeStyle(.primary))
            .frame(width: 20, height: 20)
            Text(text)
                .font(.custom("PCL English", size: 14))
        }
        .foregroundStyle(isHovered ? AppSettings.shared.theme.getTextStyle() : AnyShapeStyle(Color("TextColor")))
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if selection != value {
                selection = value
                withAnimation(.spring(duration: 0.15)) {
                    outerLength = 10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.65, blendDuration: 0.2)) {
                        outerLength = 20
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered in
            self.isHovered = isHovered
        }
    }
}

#Preview {
    MyComboBoxItemComponent(selection: .constant(1), value: 2, text: "")
        .padding()
}

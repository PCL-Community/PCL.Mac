//
//  MyTagComponent.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/22.
//

import SwiftUI

struct MyTagComponent: View {
    let label: String
    let backgroundColor: Color
    let fontSize: CGFloat
    
    init(label: String, backgroundColor: Color = .white, fontSize: CGFloat = 14) {
        self.label = label
        self.backgroundColor = backgroundColor
        self.fontSize = fontSize
    }
    
    var body: some View {
        Text(label)
            .font(.custom("PCL English", size: fontSize))
            .padding(2)
            .foregroundStyle(.primary)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .foregroundStyle(backgroundColor)
            )
    }
}

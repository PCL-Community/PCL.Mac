//
//  MyTipComponent.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/20.
//

import SwiftUI

struct MyTipComponent: View {
    let text: String
    let color: TipColor
    
    var body: some View {
        HStack {
            Rectangle()
                .frame(width: 3)
                .foregroundStyle(color.textColor)
            Text(text)
                .font(.custom("PCL English", size: 14))
                .foregroundStyle(color.textColor)
                .padding(EdgeInsets(top: 9, leading: 0, bottom: 9, trailing: 12))
            Spacer()
        }
        .background(color.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

enum TipColor {
    case blue, red, yellow
    
    private var hue: Double {
        switch self {
        case .blue: 210
        case .red: 355
        case .yellow: 40
        }
    }
    
    fileprivate var backgroundColor: Color { .init(h2: hue, s2: 90, l2: ColorConstants.L7) }
    
    fileprivate var textColor: Color { .init(h2: hue, s2: 90, l2: ColorConstants.L2) }
}

#Preview {
    MyTipComponent(text: "这是一行测试文本", color: .blue)
        .padding()
        .background(Theme.pcl.getBackgroundStyle())
}

//
//  WindowControlButton.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/17.
//

import SwiftUI

struct WindowControlButton: View {
    static let Close: WindowControlButton = .init(
    Image(systemName: "xmark")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 13)
        .foregroundStyle(.white)
        .bold()
    ) {
        NSApplication.shared.terminate(nil)
    }
    
    static let Miniaturize: WindowControlButton = .init(
    Image(systemName: "minus")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 13)
        .foregroundStyle(.white)
        .bold()
    ) {
        NSApplication.shared.windows.first!.miniaturize(nil)
    }
    
    static let Back: WindowControlButton = .init(
    Image("Back")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(height: 18)
        .foregroundStyle(.white)
        .padding(.top, 3)
    ) {
        if DataManager.shared.router.getLastView() is SubRouteContainer {
            DataManager.shared.router.removeLast()
        }
        DataManager.shared.router.removeLast()
    }
    
    let action: () -> Void
    private let view: any View
    @State private var isHovered = false
    
    init(_ view: any View, action: @escaping () -> Void) {
        self.view = view
        self.action = action
    }

    var body: some View {
        VStack {
            AnyView(view)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isHovered ? Color(hex: 0xFFFFFF, alpha: 0.17) : Color.clear)
                        .animation(.easeInOut(duration: 0.2), value: isHovered)
                        .frame(width: 30, height: 30)
                )
        }
        .frame(width: 30, height: 30)
        .onHover { hover in
            isHovered = hover
        }
        .onTapGesture(perform: action)
    }
}

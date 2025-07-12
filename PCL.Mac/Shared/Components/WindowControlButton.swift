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
    
    static let MacOSClose: WindowControlButton = .init{ isHovered in
        Circle()
            .fill(Color(hex: 0xFF5F57))
            .overlay {
                if isHovered {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .bold()
                        .frame(width: 6)
                        .foregroundStyle(Color(hex: 0x000000, alpha: 0.4))
                }
            }
            .frame(width: 12)
    } action: {
        Close.action()
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
    
    static let MacOSMiniaturize: WindowControlButton = .init{ isHovered in
        Circle()
            .fill(Color(hex: 0xFEBC2E))
            .overlay {
                if isHovered {
                    Image(systemName: "minus")
                        .resizable()
                        .scaledToFit()
                        .bold()
                        .frame(width: 8)
                        .foregroundStyle(Color(hex: 0x000000, alpha: 0.4))
                }
            }
            .frame(width: 12)
    } action: {
        Miniaturize.action()
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
    
    static let MacOSBack: WindowControlButton = .init{ isHovered in
        Circle()
            .fill(Color(hex: 0x28C840))
            .overlay {
                if isHovered {
                    Image("Back")
                        .resizable()
                        .scaledToFit()
                        .bold()
                        .frame(width: 8)
                        .foregroundStyle(Color(hex: 0x000000, alpha: 0.4))
                }
            }
            .frame(width: 12)
    } action: {
        Back.action()
    }
    
    let action: () -> Void
    private let content: (Bool) -> any View
    @State private var isHovered = false
    
    init(@ViewBuilder _ content: @escaping (Bool) -> some View, action: @escaping () -> Void) {
        self.content = content
        self.action = action
    }
    
    init(_ view: some View, action: @escaping () -> Void) {
        self.content = { isHovered in
            view
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isHovered ? Color(hex: 0xFFFFFF, alpha: 0.17) : Color.clear)
                        .animation(.easeInOut(duration: 0.2), value: isHovered)
                        .frame(width: 30, height: 30)
                )
                .frame(width: 30, height: 30)
        }
        self.action = action
    }

    var body: some View {
        AnyView(content(isHovered))
            .onHover { hover in
                isHovered = hover
            }
            .onTapGesture(perform: action)
    }
}

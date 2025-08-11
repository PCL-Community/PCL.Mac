//
//  PopupOverlay.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/19.
//
// 我是萌新，请问 PopupOverlay 是刷妈塔吗

import SwiftUI

enum PopupAnimationState {
    case beforePop, popped, afterCollapse
    
    func getRotation() -> Angle {
        switch self {
        case .beforePop: Angle(degrees: -10)
        case .popped: Angle(degrees: 0)
        case .afterCollapse: Angle(degrees: 5)
        }
    }
    
    func getRotationAnchor() -> UnitPoint {
        switch self {
        case .beforePop: UnitPoint(x: 1, y: 0)
        case .popped: UnitPoint(x: 0, y: 0)
        case .afterCollapse: UnitPoint(x: 0, y: 1)
        }
    }
}

enum PopupType {
    case normal, error
    
    func getMaskColor() -> Color {
        switch self {
        case .normal: Color(hex: 0x000000, alpha: 0.7)
        case .error: Color(hex: 0x470000, alpha: 0.7)
        }
    }
    
    func getTextStyle() -> AnyShapeStyle {
        switch self {
        case .normal: AppSettings.shared.theme.getTextStyle()
        case .error: AnyShapeStyle(Color(hex: 0xF50000))
        }
    }
}

struct PopupOverlay: View, Identifiable, Equatable {
    @ObservedObject private var popupManager: PopupManager = .shared
    
    @State private var stateNoAnim: PopupAnimationState = PopupManager.shared.popupState
    
    private let width: CGFloat = 560
    private let height: CGFloat = 280
    
    private let model: PopupModel
    
    public let id: UUID = UUID()
    
    public init(_ model: PopupModel) {
        self.model = model
    }
    
    public static func == (_ var1: PopupOverlay, _ var2: PopupOverlay) -> Bool {
        return var1.id == var2.id
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color("MyCardBackgroundColor"))
                .frame(width: width + 20, height: height + 20)
                .shadow(color: Color("TextColor"), radius: 2)
            HStack {
                VStack {
                    Text(model.title)
                        .font(.custom("PCL English", size: 30))
                        .frame(maxWidth: width - 40, alignment: .leading)
                    Rectangle()
                        .frame(width: width - 20, height: 2)
                        .padding(.top, -10)
                    Text(model.content)
                        .font(.custom("PCL English", size: 14))
                        .foregroundStyle(Color("TextColor"))
                        .frame(maxWidth: width - 40, alignment: .leading)
                    Spacer()
                    HStack {
                        Spacer()
                        ForEach(model.buttons, id: \.self) { button in
                            PopupButton(model: button)
                                .padding()
                                .foregroundStyle(Color("MyCardBackgroundColor"))
                        }
                    }
                }
                .foregroundStyle(model.type.getTextStyle())
            }
            .frame(width: width, height: height)
        }
        .rotationEffect(popupManager.popupState.getRotation(), anchor: stateNoAnim.getRotationAnchor())
        .opacity(popupManager.popupState == .popped ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: popupManager.popupState)
        .onAppear {
            popupManager.popupState = .popped
        }
        .onChange(of: popupManager.popupState) {
            withAnimation(nil) {
                stateNoAnim = popupManager.popupState
            }
        }
    }
}

#Preview {
//    PopupOverlay("Minecraft 出现错误", "错就发报告\n错不起就别问", [])
//        .padding()
//        .background(Color(hex: 0xC4D9F2))
    ContentView()
}

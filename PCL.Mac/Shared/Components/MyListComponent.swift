//
//  MyListComponent.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/19.
//

import SwiftUI

struct MyListComponent<Content: View>: View {
    @ObservedObject private var dataManager: DataManager = .shared
    
    let content: (AppRoute, Bool) -> Content
    @Binding var cases: [AppRoute]
    let animationIndex: Int
    let height: CGFloat
    @State private var hovering: AppRoute? = nil
    @State private var appeared: Set<AppRoute> = []
    
    init(root: AppRoute? = nil, cases: Binding<[AppRoute]>, animationIndex: Int = 0, height: CGFloat = 32, @ViewBuilder content: @escaping (AppRoute, Bool) -> Content) {
        self._cases = cases
        self.content = content
        self.animationIndex = animationIndex
        self.height = height
        if let root = root, dataManager.router.getLast() == root {
            dataManager.router.append(cases.first!.wrappedValue)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(cases.indices, id: \.self) { index in
                let item = cases[index]
                RouteView(content: content, item: item, height: height)
                    .offset(x: appeared.contains(item) ? 0 : -dataManager.leftTabWidth / 2)
                    .opacity(appeared.contains(item) ? 1 : 0)
                    .onAppear {
                        if !appeared.contains(item) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index + animationIndex) * 0.038) {
                                let item1 = item
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                                    _ = appeared.insert(item1)
                                }
                            }
                        }
                    }
            }
        }
    }
}

fileprivate struct RouteView<Content: View>: View {
    @ObservedObject private var dataManager: DataManager = .shared
    
    @State private var isHovered: Bool = false
    @State private var indicatorHeight: CGFloat
    
    let content: (AppRoute, Bool) -> Content
    let item: AppRoute
    let height: CGFloat
    
    init(content: @escaping (AppRoute, Bool) -> Content, item: AppRoute, height: CGFloat) {
        self.content = content
        self.item = item
        self.height = height
        self.indicatorHeight = height - 8
    }
    
    var body: some View {
        HStack {
            Group {
                if dataManager.router.getLast().isSame(item) {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(AnyShapeStyle(AppSettings.shared.theme.getTextStyle()))
                } else {
                    Color.clear
                }
            }
            .frame(width: 4, height: indicatorHeight)
            
            content(item, dataManager.router.getLast().isSame(item))
                .frame(height: height)
                .padding(.leading, 5)
                .animation(.easeInOut(duration: 0.2), value: dataManager.router.getLast())
            Spacer()
        }
        .background(isHovered ? Color(hex: 0x1370F3, alpha: 0.1) : Color.clear)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .contentShape(Rectangle())
        .onHover { hover in
            isHovered = hover
        }
        .onTapGesture {
            if dataManager.router.getLast().isSame(item) { return }
            dataManager.router.removeLast()
            dataManager.router.append(item)
            indicatorHeight = 10
            withAnimation(.spring(duration: 0.2)) {
                indicatorHeight = height - 8
            }
        }
    }
}

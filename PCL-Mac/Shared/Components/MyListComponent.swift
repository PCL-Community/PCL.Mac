//
//  MyListComponent.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/6/19.
//

import SwiftUI

struct MyListComponent<Content: View>: View {
    @ObservedObject private var dataManager: DataManager = .shared
    
    let content: (AppRoute, Bool) -> Content
    let cases: [AppRoute]
    @State private var hovering: AppRoute? = nil
    @State private var appeared: Set<AppRoute> = []
    
    init(`default`: AppRoute? = nil, cases: [AppRoute], @ViewBuilder content: @escaping (AppRoute, Bool) -> Content) {
        self.cases = cases
        self.content = content
        if let `default` = `default` {
            dataManager.router.append(`default`)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(cases.indices, id: \.self) { index in
                let item = cases[index]
                RouteView(content: content, item: item)
                // 动画部分
                .offset(x: appeared.contains(item) ? 0 : -40)
                .opacity(appeared.contains(item) ? 1 : 0)
                .onAppear {
                    if !appeared.contains(item) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.09) {
                            let item1 = item
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
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
    @State private var indicatorHeight: CGFloat = 24
    
    let content: (AppRoute, Bool) -> Content
    let item: AppRoute
    
    var body: some View {
        HStack {
            Group {
                if dataManager.router.getLast() == item {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(AnyShapeStyle(AppSettings.shared.theme.getTextStyle()))
                } else {
                    Color.clear
                }
            }
            .frame(width: 4, height: indicatorHeight)
            
            content(item, dataManager.router.getLast() == item)
                .frame(height: 32)
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
            if dataManager.router.getLast() == item { return }
            dataManager.router.removeLast()
            dataManager.router.append(item)
            indicatorHeight = 10
            withAnimation(.spring(duration: 0.2)) {
                indicatorHeight = 24
            }
        }
    }
}

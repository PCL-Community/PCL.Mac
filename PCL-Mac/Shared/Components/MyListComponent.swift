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
    @State private var indicatorHeight: CGFloat = 24
    @State private var hovering: AppRoute? = nil

    init(`default`: AppRoute? = nil, cases: [AppRoute], @ViewBuilder content: @escaping (AppRoute, Bool) -> Content) {
        self.cases = cases
        self.content = content
        if let `default` = `default` {
            dataManager.router.append(`default`)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(cases, id: \.self) { item in
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
                .background(hovering == item ? Color(hex: 0x1370F3, alpha: 0.1) : Color.clear)
                .animation(.spring(duration: 0.2), value: hovering)
                .contentShape(Rectangle())
                .onTapGesture {
                    if dataManager.router.getLast() == item { return }
                    dataManager.router.removeLast()
                    dataManager.router.append(item)
                    indicatorHeight = 10
                    withAnimation(.spring(duration: 0.2)) {
                        indicatorHeight = 24
                    }
                }
                .onHover { hover in
                    hovering = hover ? item : nil
                }
            }
        }
    }
}

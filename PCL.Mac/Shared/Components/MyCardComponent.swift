//
//  ListComponent.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/18.
//

import SwiftUI

struct BaseCardContainer<Content: View>: View {
    @State private var isHovered: Bool = false
    @State private var isAppeared: Bool = false
    
    let content: (Binding<Bool>) -> Content
    let index: Int
    let hasAnimation: Bool
    
    init(index: Int, hasAnimation: Bool, content: @escaping (Binding<Bool>) -> Content) {
        self.index = index
        self.hasAnimation = hasAnimation
        self.content = content
    }

    var body: some View {
        content($isHovered)
            .foregroundStyle(isHovered ? AppSettings.shared.theme.getTextStyle() : .init(Color("TextColor")))
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color("MyCardBackgroundColor"))
                    .shadow(
                        color: isHovered ? AppSettings.shared.theme.getAccentColor() : .gray,
                        radius: 2, x: 0.5, y: 0.5
                    )
            )
            .padding(.top, -23)
            .opacity(isAppeared ? 1 : 0)
            .offset(y: isAppeared ? 25 : 0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hover in
                isHovered = hover
            }
            .onAppear {
                if hasAnimation {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                            isAppeared = true
                        }
                    }
                } else {
                    isAppeared = true
                }
            }
    }
}

fileprivate struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct MyCardComponent<Content: View>: View {
    @ObservedObject private var dataManager: DataManager = .shared

    let title: String
    let index: Int
    private let content: Content
    private var hasAnimation: Bool = true
    private var onToggle: ((Bool) -> Void)? = nil
    private var id: String? = nil
    
    @State private var isUnfolded: Bool = false // 带动画
    @State private var showContent: Bool = false // 无动画
    @State private var internalContentHeight: CGFloat = .zero
    @State private var contentHeight: CGFloat = .zero
    @State private var lastClick: Date = Date()

    init(index: Int = 0, title: String, @ViewBuilder content: @escaping () -> Content) {
        self.index = index
        self.title = title
        self.content = content()
    }

    var body: some View {
        BaseCardContainer(index: index, hasAnimation: hasAnimation) { isHovered in
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        MaskedTextRectangle(text: title)
                        Spacer()
                        Image("FoldController")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .rotationEffect(.degrees(isUnfolded ? 180 : 0), anchor: .center)
                            .foregroundStyle(.primary)
                    }
                    Color.clear
                        .contentShape(Rectangle())
                }
                .frame(height: 9)
                .onTapGesture {
                    if Date().timeIntervalSince(lastClick) < 0.2 {
                        return
                    }
                    lastClick = Date()
                    if !showContent {
                        showContent = true
                        withAnimation(.linear(duration: 0.2)) {
                            isUnfolded = true
                            onToggle?(true)
                            contentHeight = internalContentHeight
                        }
                        updateState(true)
                    } else {
                        contentHeight = min(2000, contentHeight)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85, blendDuration: 0)) {
                            isUnfolded = false
                            contentHeight = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showContent = false
                            onToggle?(false)
                        }
                        updateState(false)
                    }
                }

                ZStack(alignment: .top) {
                    content
                        .foregroundStyle(Color("TextColor"))
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(key: ContentHeightKey.self, value: proxy.size.height)
                            }
                        )
                        .opacity(showContent ? 1 : 0)
                }
                .frame(height: contentHeight, alignment: .top)
                .clipped()
                .padding(.top, showContent ? 10 : 0)
                .animation(.easeInOut(duration: 0.3), value: isUnfolded)
                .animation(.easeInOut(duration: 0.3), value: contentHeight)
            }
            .onPreferenceChange(ContentHeightKey.self) { h in
                if h > 0 { internalContentHeight = h }
            }
        }
        .onAppear {
            loadState()
        }
    }
    
    func onToggle(_ callback: @escaping (Bool) -> Void) -> MyCardComponent {
        var copy = self
        copy.onToggle = callback
        return copy
    }
    
    func cardId(_ id: String) -> MyCardComponent {
        var copy = self
        copy.id = id
        copy.loadState()
        return copy
    }
    
    private func loadState() {
        if let id = id, let state = StateManager.shared.cardStates[id] {
            self.isUnfolded = state
            self.showContent = state
            if state {
                onToggle?(true)
                contentHeight = internalContentHeight
            }
        }
    }
    
    private func updateState(_ state: Bool) {
        if let id = id {
            StateManager.shared.cardStates[id] = state
        }
    }
    
    func noAnimation() -> MyCardComponent {
        var copy = self
        copy.hasAnimation = false
        return copy
    }
}

struct StaticMyCardComponent<Content: View>: View {
    @ObservedObject private var dataManager: DataManager = .shared

    let index: Int
    let title: String
    let content: () -> Content
    
    private var hasAnimation: Bool = true
    
    init(index: Int = 0, title: String, content: @escaping () -> Content) {
        self.index = index
        self.title = title
        self.content = content
    }

    var body: some View {
        BaseCardContainer(index: index, hasAnimation: hasAnimation) { _ in
            VStack {
                MaskedTextRectangle(text: title)
                content()
                    .foregroundStyle(Color("TextColor"))
            }
        }
    }
    
    func noAnimation() -> StaticMyCardComponent {
        var copy = self
        copy.hasAnimation = false
        return copy
    }
}

struct TitlelessMyCardComponent<Content: View>: View {
    let content: () -> Content
    let index: Int
    
    private var hasAnimation: Bool = true
    
    init(index: Int = 0, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.index = index
    }

    var body: some View {
        BaseCardContainer(index: index, hasAnimation: hasAnimation) { _ in
            VStack {
                content()
                    .foregroundStyle(Color("TextColor"))
            }
        }
    }
    
    func noAnimation() -> TitlelessMyCardComponent {
        var copy = self
        copy.hasAnimation = false
        return copy
    }
}

struct MaskedTextRectangle: View {
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .mask(
                            HStack {
                                Text(text)
                                    .font(.custom("PCL English", size: 14))
                                    .fixedSize()
                                Spacer()
                            }
                        )
                }
            }
            .frame(height: 14)
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .padding()
        .background(Color(hex: 0xC7D9F0))
}

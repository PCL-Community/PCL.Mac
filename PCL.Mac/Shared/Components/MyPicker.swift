//
//  MyPicker.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/27.
//

import SwiftUI

struct MyPicker<Entry: Hashable>: View {
    @ObservedObject private var overlayManager: OverlayManager = .shared
    @Binding private var selected: Entry
    @State private var isHovered: Bool = false
    @State private var showMenu: Bool = false
    @State private var overlayId: UUID? = nil
    @FocusState private var isFocused: Bool
    
    private let entries: [Entry]
    private let getText: (Entry) -> String
    
    init(selected: Binding<Entry>, entries: [Entry], textProvider: @escaping (Entry) -> String) {
        self._selected = selected
        self.entries = entries
        self.getText = textProvider
    }
    
    var body: some View {
        MyGeometryReader { geo in
            ZStack(alignment: .leading) {
                HStack {
                    Text(getText(selected))
                        .font(.custom("PCL English", size: 14))
                        .foregroundStyle(Color("TextColor"))
                        .padding(.leading, 5)
                        .lineLimit(1)
                    Spacer()
                    Image("FoldController")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .rotationEffect(.degrees(showMenu ? 180 : 0), anchor: .center)
                        .foregroundStyle(AppSettings.shared.theme.getAccentColor().opacity(isHovered ? 1.0 : 0.5))
                        .padding(.trailing, 5)
                }
                .animation(.easeInOut(duration: 0.3), value: showMenu)
                
                RoundedRectangle(cornerRadius: 4)
                    .stroke(AppSettings.shared.theme.getAccentColor().opacity(isHovered ? 1.0 : 0.5), lineWidth: 1.5)
                    .allowsHitTesting(false)
            }
            .animation(.easeInOut(duration: 0.2), value: self.isHovered)
            .frame(height: 27)
            .contentShape(Rectangle())
            .onTapGesture {
                if let overlayId = overlayId {
                    overlayManager.removeOverlay(with: overlayId)
                    self.overlayId = nil
                } else if let geo = geo {
                    let frame = geo.frame(in: .global)
                    overlayId = overlayManager.addOverlay(
                        view: PickerMenu(entries: entries, onSelect: { selected = $0 ; overlayManager.removeOverlay(with: self.overlayId!) }, getText: getText)
                            .frame(width: geo.size.width)
                            .foregroundStyle(AppSettings.shared.theme.getAccentColor()),
                        at: CGPoint(x: frame.minX, y: frame.maxY + 1)
                    )
                }
            }
            .onChange(of: isFocused) {
                if isFocused == false, let overlayId = overlayId {
                    overlayManager.removeOverlay(with: overlayId)
                }
            }
            .onHover { hover in
                self.isHovered = hover
            }
        }
        .onDisappear {
            if let overlayId = overlayId {
                overlayManager.removeOverlay(with: overlayId)
                self.overlayId = nil
            }
        }
    }
}

fileprivate struct PickerMenu<Entry: Hashable>: View {
    let entries: [Entry]
    let onSelect: (Entry) -> Void
    let getText: (Entry) -> String
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ForEach(entries, id: \.self) { entry in
                    MyListItem {
                        HStack {
                            Text(getText(entry))
                                .font(.custom("PCL English", size: 14))
                                .foregroundStyle(Color("TextColor"))
                                .padding(.leading, 5)
                            Spacer()
                        }
                        .frame(height: 27)
                    }
                    .onTapGesture {
                        onSelect(entry)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("MyCardBackgroundColor"))
                    .shadow(color: Color("TextColor").opacity(0.2), radius: 4)
            }
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.primary, lineWidth: 1.5)
            }
        }
    }
}

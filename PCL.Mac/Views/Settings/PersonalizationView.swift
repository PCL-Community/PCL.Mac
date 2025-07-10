//
//  PersonalizationView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/21.
//

import SwiftUI

struct PersonalizationView: View {
    @ObservedObject private var settings: AppSettings = .shared
    
    var body: some View {
        ScrollView {
            StaticMyCardComponent(title: "配色方案") {
                HStack {
                    MyComboBoxComponent(
                        options: [ColorSchemeOption.light, ColorSchemeOption.dark, ColorSchemeOption.system],
                        selection: $settings.colorScheme,
                        label: { $0.getLabel() }) { content in
                            HStack(spacing: 120) {
                                content
                            }
                        }
                        .onChange(of: settings.colorScheme) { _ in
                            HintManager.default.add(.init(text: "重启后生效", type: .info))
                        }
                    Spacer()
                }
                .padding()
            }
            .padding()
        }
        .scrollIndicators(.never)
    }
}

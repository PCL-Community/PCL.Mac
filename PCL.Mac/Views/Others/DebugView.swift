//
//  DebugView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/20.
//

import SwiftUI

struct DebugView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject private var settings: AppSettings = .shared
    @State private var hintClickCount: Int = 0
    @State private var entries: [String] = ["test1", "test2", "test3"]
    @State private var selectedEntry: String = "test1"
    
    var body: some View {
        VStack {
            MyButton(text: "测试弹出框") {
                PopupManager.shared.show(.init(.normal, "测试", "这是一行文本\n这也是一行文本\n这是一行很\(String(repeating: "长", count: 50))的文本", [.ok]))
            }
            .frame(height: 40)
            .padding()
            .padding(.bottom, -23)
            MyButton(text: "测试错误弹出框") {
                PopupManager.shared.show(.init(.error, "测试", "这是一行文本\n这也是一行文本\n这是一行很\(String(repeating: "长", count: 50))的文本", [.ok]))
            }
            .frame(height: 40)
            .padding()
            .padding(.bottom, -23)
            MyButton(text: "测试提示") {
                switch hintClickCount % 3 {
                case 0:
                    HintManager.default.add(Hint(text: "测试普通", type: .info))
                case 1:
                    HintManager.default.add(Hint(text: "测试完成", type: .finish))
                case 2:
                    HintManager.default.add(Hint(text: "测试错误", type: .critical))
                default:
                    err("服了还必须写这个 default")
                }
                hintClickCount += 1
            }
            .frame(height: 40)
            .padding()
            .padding(.bottom, -23)
            MyButton(text: "测试配色方案更换") {
                settings.colorScheme = (settings.colorScheme == .light ? .dark : .light)
            }
            .frame(height: 40)
            .padding()
            .padding(.bottom, -23)
            MyComboBox(
                options: [ColorSchemeOption.light, ColorSchemeOption.dark, ColorSchemeOption.system],
                selection: $settings.colorScheme,
                label: { $0.getLabel() }) { content in
                HStack(spacing: 10) {
                    content
                }
            }
            .padding()
            MyPicker(selected: $selectedEntry, entries: entries, textProvider: { $0 })
                .padding()
            Spacer()
        }
    }
}

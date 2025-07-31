//
//  InstanceSettingsView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/31.
//

import SwiftUI

struct InstanceSettingsView: View {
    @State var instance: MinecraftInstance
    @State private var memoryText: String
    
    let qosOptions: [QualityOfService] = [
        .userInteractive,
        .userInitiated,
        .default,
        .utility,
        .background
    ]
    
    init(instance: MinecraftInstance) {
        self.instance = instance
        self.memoryText = String(instance.config.maxMemory)
    }
    
    var body: some View {
        ScrollView {
            StaticMyCardComponent(title: "进程设置") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("游戏内存")
                        MyTextFieldComponent(text: $memoryText, numberOnly: true)
                            .onChange(of: memoryText) { new in
                                if let intValue = Int(new) {
                                    instance.config.maxMemory = Int32(intValue)
                                    instance.saveConfig()
                                }
                            }
                        Text("MB")
                    }
                    VStack(spacing: 2) {
                        HStack {
                            Text("进程 QoS")
                            MyPickerComponent(selected: $instance.config.qualityOfService, entries: qosOptions, textProvider: getQualityOfServiceName(_:))
                            .onChange(of: instance.config.qualityOfService) { _ in
                                instance.saveConfig()
                            }
                        }
                        
                        Text("​QoS 是控制进程 CPU 优先级的属性，可调整多任务下的资源分配，保障游戏进程优先运行，推荐默认。")
                            .font(.custom("PCL English", size: 12))
                            .foregroundStyle(Color(hex: 0x8C8C8C))
                            .padding(.top, 2)
                    }
                }
                .padding()
            }
            .padding()
        }
        .font(.custom("PCL English", size: 14))
        .scrollIndicators(.never)
    }
    
    private func getQualityOfServiceName(_ qos: QualityOfService) -> String {
        switch qos {
        case .userInteractive:
            "用户交互 (最高优先级)"
        case .userInitiated:
            "用户启动 (高优先级)"
        case .utility:
            "实用工具 (低优先级)"
        case .background:
            "后台 (最低优先级)"
        case .default:
            "默认"
        @unknown default:
            "未知"
        }
    }
}

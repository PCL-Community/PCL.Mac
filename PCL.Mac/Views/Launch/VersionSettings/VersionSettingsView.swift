//
//  VersionSettingsView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/16.
//

import SwiftUI

struct VersionSettingsView: View, SubRouteContainer {
    @ObservedObject private var dataManager: DataManager = .shared
    
    private let instance: MinecraftInstance!
    
    init() {
        if let directory = AppSettings.shared.currentMinecraftDirectory,
           let defaultInstance = AppSettings.shared.defaultInstance,
           let instance = MinecraftInstance.create(directory, directory.versionsUrl.appending(path: defaultInstance)) {
            self.instance = instance
        } else {
            self.instance = nil
        }
    }
    
    var body: some View {
        Group {
            switch dataManager.router.getLast() {
            case .instanceOverview:
                InstanceOverviewView(instance: instance)
            case .instanceSettings:
                InstanceSettingsView(instance: instance)
            default:
                Spacer()
            }
        }
        .onAppear {
            dataManager.leftTab(200) {
                VStack(alignment: .leading, spacing: 0) {
                    MyListComponent(
                        default: .instanceOverview,
                        cases: .constant(
                            [
                                .instanceOverview,
                                .instanceSettings,
                                .instanceMods
                            ]
                        )) { route, isSelected in
                            createListItemView(route)
                                .foregroundStyle(isSelected ? AnyShapeStyle(AppSettings.shared.theme.getTextStyle()) : AnyShapeStyle(Color("TextColor")))
                        }
                        .padding(.top, 10)
                    Spacer()
                }
            }
        }
    }
    
    private func createListItemView(_ route: AppRoute) -> some View {
        let imageName: String
        let text: String
        
        switch route {
        case .instanceOverview:
            imageName = "GameDownloadIcon"
            text = "概览"
        case .instanceSettings:
            imageName = "SettingsIcon"
            text = "设置"
        case .instanceMods:
            imageName = "ModDownloadIcon"
            text = "Mod 管理"
        default:
            return AnyView(EmptyView())
        }
        
        return AnyView(
            HStack {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(text)
                    .font(.custom("PCL English", size: 14))
            }
        )
    }
}

struct InstanceOverviewView: View {
    let instance: MinecraftInstance
    
    var body: some View {
        ScrollView {
            TitlelessMyCardComponent {
                HStack {
                    Image(instance.getIconName())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32)
                    VStack(alignment: .leading) {
                        Text(instance.config.name)
                        Text(getVersionString())
                            .foregroundStyle(Color(hex: 0x8C8C8C))
                    }
                    .font(.custom("PCL English", size: 14))
                    .foregroundStyle(Color("TextColor"))
                    Spacer()
                }
            }
            .padding()
        }
        .scrollIndicators(.never)
    }
    
    private func getVersionString() -> String {
        var str = instance.version.displayName
        if instance.clientBrand != .vanilla {
            str += ", \(instance.clientBrand.getName())"
        }
        
        return str
    }
}

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
            StaticMyCardComponent(title: "进程管理") {
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
                            Picker("进程 QoS", selection: $instance.config.qualityOfService) {
                                ForEach(qosOptions, id: \.self) { option in
                                    Text(getQualityOfServiceName(option))
                                }
                            }
                            .onChange(of: instance.config.qualityOfService) { _ in
                                instance.saveConfig()
                            }
                            Spacer()
                        }
                        
                        Text("​QoS 是控制进程 CPU 优先级的属性，可调整多任务下的资源分配，保障游戏进程优先运行，推荐默认。")
                            .font(.custom("PCL English", size: 12))
                            .foregroundStyle(Color(hex: 0x8C8C8C))
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

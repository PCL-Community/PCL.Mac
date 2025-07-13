//
//  JavaSettingsView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/21.
//

import SwiftUI

struct JavaSettingsView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    
    var body: some View {
        ScrollView {
            TitlelessMyCardComponent {
                Text("搜索耗时: \(dataManager.lastTimeUsed)ms")
                    .font(.custom("PCL English", size: 14))
                HStack {
                    MyButtonComponent(text: "刷新 Java 列表") {
                        do {
                            try JavaSearch.searchAndSet()
                        } catch {
                            print("无法刷新Java列表: \(error)")
                        }
                    }
                    .frame(height: 40)
                    MyButtonComponent(text: "手动添加 Java") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseFiles = true
                        panel.canChooseDirectories = false
                        
                        if panel.runModal() == .OK {
                            let url = panel.url!
                            if url.lastPathComponent == "java" {
                                if dataManager.javaVirtualMachines.filter({ $0.executableUrl == url }).isEmpty {
                                    let jvm = JavaVirtualMachine.of(url, true)
                                    if !jvm.isError {
                                        AppSettings.shared.userAddedJvmPaths.append(url)
                                        dataManager.javaVirtualMachines.append(jvm)
                                    } else {
                                        err("发生错误，无法手动添加 Java")
                                    }
                                } else {
                                    err("无法手动添加 Java: 已有重复的 Java")
                                }
                            } else {
                                err("无法手动添加 Java: 可执行文件不正确")
                            }
                        }
                    }
                    .frame(height: 40)
                }
                VStack {
                    ForEach(dataManager.javaVirtualMachines) { javaEntity in
                        JavaComponent(jvm: javaEntity)
                    }
                    .animation(.easeInOut(duration: 0.2), value: dataManager.javaVirtualMachines)
                }
                .padding()
            }
            .padding()
            .padding(.bottom, 30)
            .foregroundStyle(Color("TextColor"))
        }
        .scrollIndicators(.never)
    }
}

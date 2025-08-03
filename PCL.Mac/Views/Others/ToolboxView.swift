//
//  ToolboxView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/24.
//

import SwiftUI

struct ToolboxView: View {
    @ObservedObject private var settings: AppSettings = .shared
    
    @State private var downloadUrl: String = ""
    @State private var errorMessage: String = ""
    @State private var customFilesSaveUrl: String = AppSettings.shared.customFilesSaveUrl.path
    @State private var fileName: String = ""
    
    var body: some View {
        ScrollView {
            StaticMyCardComponent(title: "下载自定义文件") {
                VStack {
                    Text("使用 PCL.Mac 的高速多线程下载引擎下载任意文件。请注意，部分网站（例如百度网盘）可能还会报错 (403) 已禁止，无法正常下载。\n注：自定义下载进度获取暂未完成，所以显示 0.0% 是正常的！")
                    CustomDownloadOption(label: "下载地址", $downloadUrl) { urlString in
                        if let scheme = URL(string: urlString)?.scheme, scheme == "http" || scheme == "https" {
                            return ""
                        } else {
                            return "输入的网址无效！"
                        }
                    }
                    HStack {
                        CustomDownloadOption(label: "保存到", $customFilesSaveUrl) { urlString in
                            let url = URL(fileURLWithUserPath: urlString)
                            var isDirectory: ObjCBool = false
                            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                            let isValid = url.isFileURL && exists && isDirectory.boolValue
                            if isValid {
                                settings.customFilesSaveUrl = url
                            }
                            return isValid ? "" : "无效的保存位置！"
                        }
                        Text("选择")
                            .onTapGesture {
                                let panel = NSOpenPanel()
                                panel.canChooseFiles = false
                                panel.canChooseDirectories = true
                                panel.allowsMultipleSelection = false
                                panel.prompt = "选择文件夹"
                                
                                let result = panel.runModal()
                                if result == .OK, let url = panel.urls.first {
                                    settings.customFilesSaveUrl = url
                                }
                            }
                            .onChange(of: settings.customFilesSaveUrl) { _ in
                                customFilesSaveUrl = settings.customFilesSaveUrl.path
                            }
                    }
                    CustomDownloadOption(label: "文件名", $fileName) { !$0.isEmpty && $0 != "." && $0 != ".." && !$0.contains("/") && $0.utf8.count <= 255 ? "" : "文件名无效！" }
                        .onChange(of: downloadUrl) { _ in
                            if let url = URL(string: downloadUrl),
                               let fileName = Util.getFileName(url: url) {
                                self.fileName = fileName
                            } else {
                                self.fileName = UUID().uuidString
                            }
                        }
                    
                    HStack(spacing: 10) {
                        MyButtonComponent(text: "开始下载", foregroundStyle: settings.theme.getTextStyle()) {
                            guard let url = URL(string: downloadUrl),
                                  let scheme = url.scheme,
                                  scheme == "http" || scheme == "https" else {
                                hint("URL 无效！", .critical)
                                return
                            }
                            
                            let task = CustomFileDownloadTask(url: url, destination: settings.customFilesSaveUrl.appending(path: fileName))
                            DataManager.shared.inprogressInstallTasks = .single(task, key: "customFile")
                            task.start()
                            hint("开始下载 \(fileName)")
                        }
                        .frame(width: 140)
                        
                        MyButtonComponent(text: "打开文件夹") {
                            NSWorkspace.shared.open(settings.customFilesSaveUrl)
                        }
                        .frame(width: 140)
                    }
                    .frame(height: 35)
                    .padding(.top)
                }
                .font(.custom("PCL English", size: 14))
                .foregroundStyle(Color("TextColor"))
                .padding()
            }
            .padding()
        }
        .scrollIndicators(.never)
    }
}

fileprivate struct CustomDownloadOption: View {
    @Binding private var text: String
    @State private var errorMessage: String = ""
    
    private let label: String
    private let check: (String) -> String
    
    init(label: String, _ text: Binding<String>, check: @escaping (String) -> String) {
        self.label = label
        self._text = text
        self.check = check
    }
    
    var body: some View {
        HStack {
            HStack {
                Text(label)
                Spacer()
            }
            .frame(width: 100)
            VStack {
                MyTextFieldComponent(text: $text)
                    .onChange(of: text) { _ in
                        withAnimation(.spring(duration: 0.2)) {
                            errorMessage = check(text)
                        }
                    }
                if !errorMessage.isEmpty {
                    HStack {
                        Text(errorMessage)
                            .foregroundStyle(Color(hex: 0xFF4C4C))
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    ToolboxView()
}

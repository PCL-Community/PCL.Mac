//
//  MainView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/18.
//

import SwiftUI

fileprivate struct LeftTab: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject private var accountManager: AccountManager = .shared
    
    @State private var instance: MinecraftInstance?
    
    private var accountView: some View {
        MyListItemComponent {
            VStack {
                if let account = accountManager.getAccount() {
                    MinecraftAvatarComponent(type: .username, src: account.name)
                    Text(account.name)
                        .font(.custom("PCL English", size: 16))
                        .foregroundStyle(Color("TextColor"))
                } else {
                    Image("Missingno")
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 58)
                        .padding(6)
                    Text("无账号")
                        .font(.custom("PCL English", size: 16))
                        .foregroundStyle(Color("TextColor"))
                }
                Text("点击头像进入账号管理")
                    .font(.custom("PCL English", size: 10))
                    .foregroundStyle(Color(hex: 0x8C8C8C))
                    .padding(.top, 2)
            }
            .padding(4)
        }
        .onTapGesture {
            dataManager.router.append(.accountManagement)
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            accountView
            Spacer()
            if let instance = self.instance {
                MyButtonComponent(text: "启动游戏", descriptionText: instance.config.name, foregroundStyle: AppSettings.shared.theme.getTextStyle()) {
                    let launchOptions: LaunchOptions = .init()
                    
                    guard launchPrecheck(launchOptions) else { return }
                    Task {
                        debug("正在启动游戏")
                        await instance.launch(launchOptions)
                    }
                }
                .frame(height: 55)
                .padding()
                .padding(.bottom, -27)
            } else {
                MyButtonComponent(text: "下载游戏", descriptionText: "未找到可用的游戏版本") {
                    dataManager.router.setRoot(.download)
                }
                .frame(height: 55)
                .padding()
                .padding(.bottom, -27)
            }
            HStack(spacing: 12) {
                MyButtonComponent(text: "版本选择") {
                    dataManager.router.append(.versionSelect)
                }
                if AppSettings.shared.defaultInstance != nil {
                    MyButtonComponent(text: "版本设置") {
                        if let instance = self.instance {
                            dataManager.router.append(.versionSettings(instance: instance))
                        }
                    }
                }
            }
            .frame(height: 32)
            .padding()
            .padding(.bottom, 4)
        }
        .frame(width: 300)
        .foregroundStyle(Color(hex: 0x343D4A))
        .onAppear {
            if let directory = AppSettings.shared.currentMinecraftDirectory,
               let defaultInstance = AppSettings.shared.defaultInstance,
               let instance = MinecraftInstance.create(directory, directory.versionsUrl.appending(path: defaultInstance)) {
                self.instance = instance
            }
        }
    }
    
    private func launchPrecheck(_ launchOptions: LaunchOptions) -> Bool {
        var returnValue: Bool = false
        switch LaunchPrecheck.check(instance!, launchOptions) {
        case .success():
            returnValue = true
        case .failure(let error):
            switch error {
            case .invalidMemoryConfiguration:
                ContentView.setPopup(.init("错误", "就给 0MB 内存你打算咋跑啊！\n请在 版本设置 > 设置 中调整游戏内存配置", [.Ok], .error))
            case .missingAccount:
                ContentView.setPopup(PopupOverlay("错误", "请先创建一个账号并选择再启动游戏！", [.Ok], .error))
            case .javaNotFound:
                ContentView.setPopup(.init("错误", "你还没有安装 Java\n如果你安装过 Java 并且没有在 Java 管理中看到，请点击“手动添加 Java”", [.init(text: "安装 Java", onClick: { NSWorkspace.shared.open(URL(string: "https://www.azul.com/downloads/?package=jdk#zulu")!) ; PopupButton.Close.onClick() }), .Close], .error))
            case .noUsableJava(let minVersion):
                ContentView.setPopup(.init("错误", "当前没有满足条件的 Java 版本\n你需要安装 \(minVersion) 及以上版本的 Java！", [.init(text: "安装 Java", onClick: { NSWorkspace.shared.open(URL(string: "https://www.azul.com/downloads/?package=jdk#zulu")!) ; PopupButton.Close.onClick() }), .Close], .error))
            case .noMicrosoftAccount:
                if Locale.current.identifier.starts(with: "zh") {
                    switch AppSettings.shared.launchCount {
                    case 3, 8, 15, 30, 50, 70, 90, 110, 130, 180, 220, 280, 330, 380, 450, 550, 660, 750, 880, 950, 1100, 1300, 1500, 1700, 1900:
                        ContentView.setPopup(.init(
                            "考虑一下正版？",
                            "你已经启动了 \(AppSettings.shared.launchCount) 次 Minecraft 啦！\n如果觉得 Minecraft 还不错，可以购买正版支持一下，毕竟开发游戏也真的很不容易……不要一直白嫖啦。\n在登录一次正版账号后，就不会再出现这个提示了！",
                            [
                                .init(text: "支持正版游戏！", onClick: { NSWorkspace.shared.open(URL(string: "https://www.xbox.com/zh-cn/games/store/minecraft-java-bedrock-edition-for-pc/9nxp44l49shj")!) ; PopupButton.Close.onClick() }),
                                .init(text: "下次一定", onClick: { PopupButton.Close.onClick() ; returnValue = true })
                            ]))
                    default:
                        returnValue = true
                    }
                } else {
                    ContentView.setPopup(.init(
                        "正版验证",
                        "你必须先登录正版账号才能启动游戏！",
                        [
                            .init(text: "购买正版", onClick: { NSWorkspace.shared.open(URL(string: "https://www.xbox.com/zh-cn/games/store/minecraft-java-bedrock-edition-for-pc/9nxp44l49shj")!) ; PopupButton.Close.onClick() }),
                            .init(text: "试玩", onClick: { launchOptions.isDemo = true ; returnValue = true ; PopupButton.Close.onClick() }),
                            .init(text: "返回", onClick: PopupButton.Close.onClick)
                        ]))
                }
            case .cancelled:
                returnValue = false
            }
        }
        
        return returnValue
    }
}

struct LaunchView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject private var announcementManager: AnnouncementManager = .shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            if let announcement = announcementManager.latest {
                announcement.createView(showHistoryButton: true)
                    .padding()
            }
            
            if SharedConstants.shared.isDevelopment {
                StaticMyCardComponent(index: 0, title: "警告") {
                    VStack(spacing: 4) {
                        Text("你正在使用开发版本的 PCL.Mac！")
                            .font(.custom("PCL English", size: 14))
                        HStack(spacing: 4) {
                            Text("如果遇到问题请")
                                .font(.custom("PCL English", size: 14))
                            Text("点击此处反馈")
                                .font(.custom("PCL English", size: 14))
                                .onTapGesture {
                                    NSWorkspace.shared.open(URL(string: "https://github.com/PCL-Community/PCL-Mac/issues/new?template=bug-反馈.md")!)
                                }
                                .foregroundStyle(AppSettings.shared.theme.getTextStyle())
                        }
                    }
                    .foregroundStyle(Color("TextColor"))
                }
                .padding()
                
                StaticMyCardComponent(index: 1, title: "日志") {
                    VStack {
                        ScrollView(.horizontal) {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(LogStore.shared.logLines) { logLine in
                                    logLineView(logLine.string)
                                        .foregroundStyle(Color("TextColor"))
                                }
                            }
                        }
                        .scrollIndicators(.never)
                        .padding(.top, 5)
                        
                        MyButtonComponent(text: "打开日志") {
                            NSWorkspace.shared.activateFileViewerSelecting([SharedConstants.shared.applicationLogUrl])
                        }
                        .frame(height: 40)
                    }
                }
                .padding()
                .padding(.bottom, 20)
            }
            Spacer()
        }
        .scrollIndicators(.never)
        .onAppear {
            dataManager.leftTab(310) {
                LeftTab()
            }
        }
    }
    
    @ViewBuilder
    func logLineView(_ line: String) -> some View {
        let regex = #"\[(INFO|WARN|ERROR|DEBUG)\]"#
        let nsLine = line as NSString
        if let match = try? NSRegularExpression(pattern: regex)
            .firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)),
           let levelRange = Range(match.range(at: 1), in: line),
           let tagRange = Range(match.range(at: 0), in: line)
        {
            let level = String(line[levelRange])
            let tag = String(line[tagRange])
            let rest = String(line[tagRange.upperBound...])
            let color: Color = {
                switch level {
                    case "INFO": return .green
                    case "WARN": return .yellow
                    case "ERROR": return .red
                    case "DEBUG": return .blue
                    default: return .primary
                }
            }()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(tag)
                    .font(.custom("PCL English", size: 14))
                    .foregroundColor(color)
                Text(rest)
                    .font(.custom("PCL English", size: 14))
            }
        } else {
            HStack {
                Text(line)
                    .font(.custom("PCL English", size: 14))
            }
        }
    }
}

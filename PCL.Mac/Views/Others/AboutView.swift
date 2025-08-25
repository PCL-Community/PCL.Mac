//
//  AboutView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/20.
//

import SwiftUI

fileprivate struct ProfileCard: View {
    let imageName: String
    let name: String
    let description: String
    let buttonName: String
    let buttonURL: String
    
    var body: some View {
        MyListItem {
            HStack {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32)
                    .clipShape(Circle())
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.custom("PCL English", size: 14))
                        .foregroundStyle(Color("TextColor"))
                    Text(description)
                        .font(.custom("PCL English", size: 14))
                        .foregroundStyle(Color(hex: 0x8C8C8C))
                }
                Spacer()
                MyButton(text: buttonName) {
                    NSWorkspace.shared.open(URL(string: buttonURL)!)
                }
                .frame(width: 160, height: 40)
            }
            .frame(maxWidth: .infinity)
            .padding(4)
        }
    }
}

struct AboutView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    var body: some View {
        ScrollView {
            StaticMyCard(index: 0, title: "关于") {
                VStack(spacing: 0) {
                    ProfileCard(
                        imageName: "LtCatt",
                        name: "龙腾猫跃",
                        description: "Plain Craft Launcher 的作者！",
                        buttonName: "赞助作者",
                        buttonURL: "https://afdian.com/a/LTCat"
                    )
                    
                    ProfileCard(
                        imageName: "YiZhiMCQiu",
                        name: "YiZhiMCQiu | Minecraft-温迪",
                        description: "PCL.Mac 的作者",
                        buttonName: "进入主页",
                        buttonURL: "https://github.com/YiZhiMCQiu"
                    )
                    
                    ProfileCard(
                        imageName: "Icon",
                        name: "PCL.Mac",
                        description: "当前版本：\(SharedConstants.shared.version)-\(SharedConstants.shared.branch)",
                        buttonName: "查看源代码",
                        buttonURL: "https://github.com/PCL-Community/PCL-Mac"
                    )
                }
                .padding(.leading)
                .padding(.trailing)
            }
            .padding()
            
            StaticMyCard(index: 1, title: "特别鸣谢") {
                VStack(spacing: 0) {
                    ProfileCard(
                        imageName: "PCLCommunity",
                        name: "PCL Community",
                        description: "Plain Craft Launcher 非官方社区",
                        buttonName: "进入主页",
                        buttonURL: "https://pclc.cc"
                    )
                    
                    ProfileCard(
                        imageName: "PCL.Proto",
                        name: "PCL.Proto",
                        description: "本项目的界面样式参考了 PCL.Proto，部分图标也来源于此",
                        buttonName: "GitHub 仓库",
                        buttonURL: "https://github.com/PCL-Community/PCL.Proto"
                    )
                }
                .padding(.leading)
                .padding(.trailing)
            }
            .padding()
            
            StaticMyCard(index: 2, title: "许可与版权声明") {
                VStack(spacing: 0) {
                    DependencyView(name: "SwiftyJSON", license: "MIT", repo: "SwiftyJSON/SwiftyJSON")
                    DependencyView(name: "ZIPFoundation", license: "MIT", repo: "weichsel/ZIPFoundation")
                    DependencyView(name: "aria2", description: "作为外部分片下载器", license: "GNU GPL v2", repo: "aria2/aria2")
                    DependencyView(name: "PCL.Mac.Daemon", description: "自动导出启动器崩溃报告的守护进程", license: "MIT", repo: "VentiStudios/PCL.Mac.Daemon")
                }
            }
            .padding()
            .padding(.bottom, 25)
        }
        .scrollIndicators(.never)
    }
    
    struct DependencyView: View {
        private let name: String
        private let description: String
        private let license: String
        private let repo: String
        
        init(name: String, description: String = "", license: String, repo: String) {
            self.name = name
            self.description = description
            self.license = license
            self.repo = repo
        }
        
        var body: some View {
            MyListItem {
                HStack {
                    VStack(alignment: .leading) {
                        HStack(spacing: 0) {
                            Text(name)
                            if !description.isEmpty {
                                Text(" | \(description)")
                                    .foregroundStyle(Color(hex: 0x8C8C8C))
                            }
                            Spacer()
                        }
                        HStack(spacing: 0) {
                            Text("\(license) | ")
                            Text(verbatim: "https://github.com/\(repo)")
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    NSWorkspace.shared.open("https://github.com/\(repo)".url)
                                }
                        }
                        .foregroundStyle(Color(hex: 0x8C8C8C))
                    }
                    Spacer()
                }
                .font(.custom("PCL English", size: 14))
                .foregroundStyle(Color("TextColor"))
                .padding(8)
            }
        }
    }
}

#Preview {
    AboutView()
        .padding()
}

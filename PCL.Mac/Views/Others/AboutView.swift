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
    let buttonUrl: String
    
    var body: some View {
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
            MyButtonComponent(text: buttonName) {
                NSWorkspace.shared.open(URL(string: buttonUrl)!)
            }
            .frame(width: 160, height: 40)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AboutView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    var body: some View {
        ScrollView {
            StaticMyCardComponent(index: 0, title: "关于") {
                VStack(spacing: 10) {
                    ProfileCard(
                        imageName: "LtCatt",
                        name: "龙腾猫越",
                        description: "Plain Craft Launcher 的作者！",
                        buttonName: "赞助作者",
                        buttonUrl: "https://afdian.com/a/LTCat"
                    )
                    
                    ProfileCard(
                        imageName: "YiZhiMCQiu",
                        name: "YiZhiMCQiu | Minecraft-温迪",
                        description: "PCL.Mac 的作者",
                        buttonName: "进入主页",
                        buttonUrl: "https://github.com/YiZhiMCQiu"
                    )
                    
                    ProfileCard(
                        imageName: "Icon",
                        name: "PCL.Mac",
                        description: "当前版本：早期开发-\(SharedConstants.shared.branch)",
                        buttonName: "查看源代码",
                        buttonUrl: "https://github.com/PCL-Community/PCL-Mac"
                    )
                }
                .padding(.leading)
                .padding(.trailing)
            }
            .padding()
            
            StaticMyCardComponent(index: 1, title: "特别鸣谢") {
                VStack(spacing: 10) {
                    ProfileCard(
                        imageName: "PCLCommunity",
                        name: "PCL Community",
                        description: "Plain Craft Launcher 非官方社区",
                        buttonName: "进入主页",
                        buttonUrl: "https://pcl-community.github.io"
                    )
                    
                    ProfileCard(
                        imageName: "PCL.Proto",
                        name: "PCL.Proto",
                        description: "本项目的界面样式参考了 PCL.Proto，部分图标也来源于此",
                        buttonName: "GitHub 仓库",
                        buttonUrl: "https://github.com/PCL-Community/PCL.Proto"
                    )
                }
                .padding(.leading)
                .padding(.trailing)
            }
            .padding()
            
            StaticMyCardComponent(index: 2, title: "许可与版权声明") {
                VStack(spacing: 0) {
                    ForEach(
                        [
                            (name: "Alamofire", license: "MIT", repo: "Alamofire/Alamofire"),
                            (name: "SwiftyJSON", license: "MIT", repo: "SwiftyJSON/SwiftyJSON"),
                            (name: "ZIPFoundation", license: "MIT", repo: "weichsel/ZIPFoundation")
                        ]
                        , id: \.name) { dependency in
                            DependencyView(name: dependency.name, license: dependency.license, repo: dependency.repo)
                        }
                }
            }
            .padding()
            .padding(.bottom, 25)
        }
        .scrollIndicators(.never)
    }
    
    struct DependencyView: View {
        let name: String
        let license: String
        let repo: String
        
        var body: some View {
            MyListItemComponent {
                HStack {
                    VStack(alignment: .leading) {
                        Text(name)
                        Text("\(license) | https://github.com/\(repo)")
                            .foregroundStyle(Color(hex: 0x8C8C8C))
                    }
                    Spacer()
                }
                .font(.custom("PCL English", size: 14))
                .foregroundStyle(Color("TextColor"))
                .padding()
            }
        }
    }
}

#Preview {
    AboutView()
        .padding()
}

//
//  VersionList.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/6/1.
//

import SwiftUI

struct VersionListView: View {
    @ObservedObject private var dataManager: DataManager = DataManager.shared
    
    let minecraftDirectory: MinecraftDirectory = MinecraftDirectory(rootUrl: URL(fileURLWithUserPath: "~/PCL-Mac-minecraft"))
    
    struct VersionView: View, Identifiable {
        let name: String
        let description: String
        let instance: MinecraftInstance
        
        let id: UUID = UUID()
        
        init(instance: MinecraftInstance) {
            self.name = instance.config.name
            self.description = instance.version!.displayName
            self.instance = instance
        }
        
        var body: some View {
            MyListItemComponent {
                HStack {
                    Image(self.instance.version!.getIconName())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35)
                        .padding(.leading, 5)
                    VStack(alignment: .leading) {
                        Text(self.name)
                            .font(.custom("PCL English", size: 14))
                            .foregroundStyle(Color("TextColor"))
                            .padding(.top, 5)
                        Text(self.description)
                            .font(.custom("PCL English", size: 14))
                            .foregroundStyle(Color(hex: 0x7F8790))
                            .padding(.bottom, 5)
                    }
                    Spacer()
                }
            }
            .onTapGesture {
                AppSettings.shared.defaultInstance = instance.config.name
                DataManager.shared.router.removeLast()
            }
            .padding(.top, -8)
        }
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack {
                MyCardComponent(title: "常规版本") {
                    VStack {
                        ForEach(minecraftDirectory.getInnerInstances().sorted(by: { $0.version! > $1.version! })) { instance in
                            VersionView(instance: instance)
                        }
                    }
                    .padding(.top, 12)
                }
                .padding()
            }
        }
        .onAppear {
            dataManager.leftTab(350) {
                EmptyView()
            }
        }
    }
}

#Preview {
    VersionListView()
}

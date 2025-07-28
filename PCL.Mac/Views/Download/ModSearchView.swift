//
//  ModDownloadView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/20.
//

import SwiftUI

fileprivate struct ImageAndTextComponent: View {
    let imageName: String
    let text: String
    
    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 16)
            Text(text)
                .font(.custom("PCL English", size: 12))
        }
    }
}

struct ModListItem: View {
    @ObservedObject var summary: NewModSummary
    @ObservedObject var state: ModSearchViewState = StateManager.shared.modSearch
    
    var body: some View {
        MyListItemComponent {
            HStack {
                if let icon = state.iconCache[summary.modId] {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image("ModIconPlaceholder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onAppear {
                            Task {
                                if let url = summary.iconUrl,
                                   let data = await Requests.get(url).data,
                                   let nsImage = NSImage(data: data) {
                                    DispatchQueue.main.async {
                                        self.state.iconCache[self.summary.modId] = Image(nsImage: nsImage)
                                    }
                                }
                            }
                        }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.name)
                        .font(.custom("PCL English", size: 16))
                        .foregroundStyle(Color("TextColor"))
                    HStack {
//                        ForEach(summary.tags, id: \.self) { tag in
//                            MyTagComponent(label: tag, backgroundColor: Color("TagColor"), fontSize: 12)
//                        }
                        
                        Text(summary.description)
                            .font(.custom("PCL English", size: 14))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundStyle(Color(hex: 0x8C8C8C))
                    
                    ZStack(alignment: .leading) {
//                        if !summary.supportDescription.isEmpty {
//                            ImageAndTextComponent(imageName: "SettingsIcon", text: summary.supportDescription)
//                        }
//                        ImageAndTextComponent(imageName: "DownloadIcon", text: summary.downloads)
//                            .offset(x: summary.supportDescription.isEmpty ? 0 : 200)
//                        ImageAndTextComponent(imageName: "UploadIcon", text: summary.lastUpdate)
//                            .offset(x: 300)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color(hex: 0x8C8C8C))
                    Spacer()
                }
                Spacer()
            }
            .padding(4)
        }
    }
}

class ModSearchViewState: ObservableObject {
    @Published var query: String = ""
    @Published var summaries: [NewModSummary]?
    @Published var error: Error?
    @Published var iconCache: [String: Image] = [:]
}

struct ModSearchView: View {
    @ObservedObject var state: ModSearchViewState = StateManager.shared.modSearch
    
    var body: some View {
        ScrollView {
            StaticMyCardComponent(title: "搜索 Mod") {
                VStack(spacing: 30) {
                    HStack(spacing: 30) {
                        Text("名称")
                            .font(.custom("PCL English", size: 14))
                        MyTextFieldComponent(text: $state.query)
                            .frame(height: 8)
                    }
                    
                    HStack(spacing: 30) {
                        Text("版本")
                            .font(.custom("PCL English", size: 14))
                        MyTextFieldComponent(text: .constant("全部 (也可自行输入)"))
                            .frame(height: 8)
                    }
                    
                    HStack(spacing: 25) {
                        MyButtonComponent(text: "搜索", foregroundStyle: AppSettings.shared.theme.getTextStyle()) {
                            searchMod()
                        }
                        .frame(width: 160, height: 40)
                        
                        MyButtonComponent(text: "重制条件") {
                            state.query = ""
                        }
                        .frame(width: 160, height: 40)
                        Spacer()
                    }
                }
                .foregroundStyle(Color("TextColor"))
                .padding()
            }
            .padding()
            
            if let summaries = state.summaries {
                TitlelessMyCardComponent {
                    VStack(spacing: 0) {
                        ForEach(summaries) { summary in
                            ModListItem(summary: summary)
                                .onTapGesture {
                                    DataManager.shared.router.append(.modDownload(summary: summary))
                                }
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            if state.summaries == nil {
                searchMod()
            }
        }
        .scrollIndicators(.never)
    }
    
    private func searchMod() {
        Task {
            do {
                let result = try await ModSearcher.shared.search(query: self.state.query)
                DispatchQueue.main.async {
                    self.state.summaries = result
                }
            } catch {
                DispatchQueue.main.async {
                    self.state.error = error
                }
            }
        }
    }
}


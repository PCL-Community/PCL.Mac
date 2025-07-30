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
    public static let tagMap: [String: String] = ["technology":"科技","magic":"魔法","adventure":"冒险","utility":"实用","optimization":"性能优化","vanilla-like":"原版风","realistic":"写实风","worldgen":"世界元素","food":"食物/烹饪","game-mechanics":"游戏机制","transportation":"运输","storage":"仓储","decoration":"装饰","mobs":"生物","equipment":"装备","social":"服务器","library":"支持库","multiplayer":"多人","challenging":"硬核","combat":"战斗","quests":"任务","kitchen-sink":"水槽包","lightweight":"轻量","simplistic":"简洁","tweaks":"改良","8x-":"极简","16x":"16x","32x":"32x","48x":"48x","64x":"64x","128x":"128x","256x":"256x","512x+":"超高清","audio":"含声音","fonts":"含字体","models":"含模型","gui":"含 UI","locale":"含语言","core-shaders":"核心着色器","modded":"兼容 Mod","fantasy":"幻想风","semi-realistic":"半写实风","cartoon":"卡通风","colored-lighting":"彩色光照","path-tracing":"路径追踪","pbr":"PBR","reflections":"反射","iris":"Iris","optifine":"OptiFine","vanilla":"原版可用"]
    
    @ObservedObject var state: ModSearchViewState = StateManager.shared.modSearch
    @State private var isHovered: Bool = false
    private let lastUpdateLabel: String
    private let summary: ModSummary
    
    init(summary: ModSummary) {
        self.summary = summary
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .full
        self.lastUpdateLabel = formatter.localizedString(for: summary.lastUpdate, relativeTo: Date()).replacingOccurrences(of: "(\\d+)", with: " $1 ", options: .regularExpression)
    }
    
    var body: some View {
        MyListItemComponent {
            HStack {
                if let icon = state.iconCache[summary.projectId] {
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
                                        self.state.iconCache[self.summary.projectId] = Image(nsImage: nsImage)
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
                        ForEach(summary.tags.compactMap { ModListItem.tagMap[$0] }, id: \.self) { tag in
                            MyTagComponent(label: tag, backgroundColor: Color("TagColor"), fontSize: 12)
                        }
                        
                        Text(summary.description)
                            .font(.custom("PCL English", size: 14))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundStyle(Color(hex: 0x8C8C8C))
                    
                    ZStack(alignment: .leading) {
                        let supportDescription = getSupportDescription()
                        if !supportDescription.isEmpty {
                            ImageAndTextComponent(imageName: "SettingsIcon", text: supportDescription)
                        }
                        ImageAndTextComponent(imageName: "DownloadIcon", text: formatNumber(summary.downloadCount))
                            .offset(x: supportDescription.isEmpty ? 0 : 200)
                        ImageAndTextComponent(imageName: "UploadIcon", text: lastUpdateLabel)
                            .offset(x: 300)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color(hex: 0x8C8C8C))
                    Spacer()
                }
                Spacer()
                if isHovered {
                    Image("PlusIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16)
                        .foregroundStyle(Color(hex: 0x8C8C8C))
                        .padding(.trailing)
                        .contentShape(Circle())
                        .onTapGesture {
                            Task {
                                if state.pendingDownloadMods.contains(where: { $0.projectId == summary.projectId }) {
                                    hint("\(summary.name) 已存在！", .critical)
                                    return
                                }
                                guard let instance = DataManager.shared.defaultInstance else {
                                    hint("请先选择一个实例！", .critical)
                                    return
                                }
                                if let versionMap = try? await ModSearcher.shared.getVersionMap(id: summary.modId),
                                   let versions = versionMap[.init(loader: instance.clientBrand, minecraftVersion: instance.version)],
                                   let version = versions.first {
                                    state.addToQueue(version)
                                } else {
                                    hint("未找到 \(instance.config.name) 可用的版本！", .critical)
                                }
                            }
                        }
                }
            }
            .padding(4)
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered in
            self.isHovered = isHovered
        }
    }
    
    private func getSupportDescription() -> String {
        var supportedVersions = summary.gameVersions.map { $0.displayName }
        var supportDescription = ""
        if summary.loaders.count == 1 {
            supportDescription.append("仅 \(summary.loaders.first!.getName())")
        } else if summary.loaders.count < 3 {
            supportDescription.append(summary.loaders.map { $0.rawValue.capitalized }.joined(separator: " / "))
        }
        
        if !supportDescription.isEmpty { supportDescription.append(" ") }
        supportedVersions.removeAll(where: { $0.starts(with: "3D-Shareware") }) // 笑点解析: 3D-Shareware-v1.34 识别成 1.34
        supportDescription.append(ModListItem.describeGameVersions(
            gameVersions: Set(supportedVersions
                .filter { MinecraftVersion(displayName: $0).type == .release}
                .map { Int($0.split(separator: ".")[1])! }).sorted(by: { $0 > $1 }),
            mcVersionHighest: Int(DataManager.shared.versionManifest!.latest.release.split(separator: ".")[1])!)
        )
        return supportDescription
    }
    
    private static func describeGameVersions(gameVersions: [Int]?, mcVersionHighest: Int) -> String {
        guard let gameVersions = gameVersions, !gameVersions.isEmpty else {
            return "仅快照版本"
        }
        
        var spaVersions: [String] = []
        var isOld = false
        var i = 0
        let count = gameVersions.count
        
        while i < count {
            let startVersion = gameVersions[i]
            var endVersion = startVersion
            
            if startVersion < 10 {
                if !spaVersions.isEmpty && !isOld {
                    break
                } else {
                    isOld = true
                }
            }
            
            var ii = i + 1
            while ii < count && gameVersions[ii] == endVersion - 1 {
                endVersion = gameVersions[ii]
                i = ii
                ii += 1
            }
            
            if startVersion == endVersion {
                spaVersions.append("1.\(startVersion)")
            } else if mcVersionHighest > -1 && startVersion >= mcVersionHighest {
                if endVersion < 10 {
                    spaVersions.removeAll()
                    spaVersions.append("全版本")
                    break
                } else {
                    spaVersions.append("1.\(endVersion)+")
                }
            } else if endVersion < 10 {
                spaVersions.append("1.\(startVersion)-")
                break
            } else if startVersion - endVersion == 1 {
                spaVersions.append("1.\(startVersion), 1.\(endVersion)")
            } else {
                spaVersions.append("1.\(startVersion)~1.\(endVersion)")
            }
            
            i += 1
        }
        
        return spaVersions.joined(separator: ", ")
    }
    
    func formatNumber(_ num: Int) -> String {
        let absNum = abs(num)
        let sign = num < 0 ? "-" : ""
        let numDouble = Double(absNum)
        
        if absNum >= 100_000_000 {
            let value = numDouble / 100_000_000
            return String(format: "%@%.2f 亿", sign, value)
        } else if absNum >= 10_000 {
            let value = numDouble / 10_000
            return String(format: "%@%.0f 万", sign, value)
        } else {
            return "\(num)"
        }
    }
}

@MainActor
class ModSearchViewState: ObservableObject {
    @Published var query: String = ""
    @Published var summaries: [ModSummary]?
    @Published var error: Error?
    @Published var iconCache: [String: Image] = [:]
    @Published var pendingDownloadMods: [ModVersion] = []
    @Published var modQueueOverlayId: UUID?
    
    public func addToQueue(_ version: ModVersion) {
        Task {
            var dependencies = Set<ModVersion>(pendingDownloadMods)
            if !dependencies.insert(version).inserted {
                hint("\(version.name) 已存在！", .critical)
                return
            }
            dependencies.removeAll()
            
            guard let instance = DataManager.shared.defaultInstance else {
                hint("请先选择一个实例！", .critical)
                return
            }
            for dependency in version.dependencies {
                if dependency.versionId == nil {
                    if let versionMap = try? await ModSearcher.shared.getVersionMap(id: dependency.summary.modId),
                       let versions = versionMap[.init(loader: instance.clientBrand, minecraftVersion: instance.version)] {
                        pendingDownloadMods.append(versions.first!)
                    } else {
                        err("依赖不存在: \(dependency.summary.modId)")
                        continue
                    }
                } else {
                    if let version = try? await ModSearcher.shared.getVersion(dependency.versionId!) {
                        pendingDownloadMods.append(version)
                    } else {
                        err("依赖 \(dependency.summary.modId) 版本 \(dependency.versionId!) 不存在")
                        continue
                    }
                }
            }
            pendingDownloadMods = pendingDownloadMods.filter { dependencies.insert($0).inserted }
            pendingDownloadMods.append(version)
            hint("已将 \(version.name) 添加至模组下载队列！", .finish)
        }
    }
}

struct ModSearchView: View {
    @ObservedObject var state: ModSearchViewState = StateManager.shared.modSearch
    
    var body: some View {
        ScrollView {
            MySearchBox(query: $state.query, placeholder: "搜索 Mod 在输入框中按下 Enter 以进行搜索") { query in
                searchMod()
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

struct ModQueueOverlay: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject private var state: ModSearchViewState = StateManager.shared.modSearch
    @State private var isHovered: Bool = false
    
    var body: some View {
        if !state.pendingDownloadMods.isEmpty && dataManager.router.path.contains(.modSearch) {
            VStack {
                Spacer()
                    .allowsHitTesting(false)
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("MyCardBackgroundColor"))
                        .frame(height: 36)
                        .shadow(color: isHovered ? Color(hex: 0x0B5BCB) : .gray, radius: 2, x: 0.5, y: 0.5)
                    HStack {
                        ForEach(state.pendingDownloadMods, id: \.self) { version in
                            MyListItemComponent {
                                (state.iconCache[version.projectId] ?? Image("ModIconPlaceholder"))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .onTapGesture {
                                state.pendingDownloadMods.removeAll(where: { $0.id == version.id })
                                hint("已移除 \(version.name)！", .finish)
                            }
                        }
                        Spacer()
                        MyButtonComponent(text: "清空") {
                            state.pendingDownloadMods.removeAll()
                            hint("已清空模组下载队列！", .finish)
                        }
                        .fixedSize()
                        MyButtonComponent(text: "开始", foregroundStyle: AppSettings.shared.theme.getTextStyle()) {
                            guard let instance = DataManager.shared.defaultInstance else {
                                hint("请先在版本列表中选择一个实例！", .critical)
                                return
                            }
                            let mods = state.pendingDownloadMods
                            let task = ModInstallTask(instance: instance, mods: mods)
                            task.onComplete {
                                hint("下载完成！", .finish)
                                state.pendingDownloadMods.removeAll()
                            }
                            DataManager.shared.inprogressInstallTasks = .single(task)
                            task.start()
                            if let id = state.modQueueOverlayId {
                                OverlayManager.shared.removeOverlay(with: id)
                                state.modQueueOverlayId = nil
                            }
                            hint("开始下载 \(state.pendingDownloadMods.count) 个模组……")
                        }
                        .fixedSize()
                    }
                    .padding(.leading, 2)
                    .padding(.trailing, 2)
                }
                .onHover { isHover in
                    self.isHovered = isHover
                }
                .padding()
            }
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .animation(.easeInOut(duration: 0.2), value: state.pendingDownloadMods)
        }
    }
}

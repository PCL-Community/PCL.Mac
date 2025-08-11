//
//  ContentView.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/17.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    @ObservedObject private var overlayManager: OverlayManager = .shared
    @ObservedObject private var popupManager: PopupManager = .shared
    
    @State private var isLeftTabVisible: Bool = true
    
    var installTaskButtonOverlay: some View {
        Group {
            if let tasks = dataManager.inprogressInstallTasks {
                if case .installing = dataManager.router.getLast() {
                    
                } else {
                    RoundedButton {
                        Image("DownloadIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                            .foregroundStyle(.white)
                    } onClick: {
                        dataManager.router.append(.installing(tasks: tasks))
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
    
    var hintOverlay: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                HintOverlay()
                Spacer()
            }
            .padding(.bottom, 50)
        }
    }
    
    var popupOverlay: some View {
        Group {
            if let currentPopup = popupManager.currentPopup {
                Rectangle()
                    .fill(currentPopup.type.getMaskColor())
                PopupOverlay(currentPopup)
                    .padding()
            }
        }
    }
    
    var routerOverlay: some View {
        Text(dataManager.router.getDebugText())
            .font(.custom("PCL English", size: 14))
            .foregroundStyle(Color("TextColor"))
            .animation(.easeInOut(duration: 0.2), value: dataManager.router.path)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .offset(y: 48)
    }
    
    // MARK: - body
    var body: some View {
        ZStack {
            createViewFromRouter()
            ForEach(overlayManager.overlays) { overlay in
                overlay.view
                    .offset(CGSize(width: overlay.position.x, height: overlay.position.y))
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            if SharedConstants.shared.isDevelopment {
                routerOverlay
            }
            installTaskButtonOverlay
            ModQueueOverlay()
            hintOverlay
            popupOverlay
        }
        .ignoresSafeArea(.container, edges: .top)
        .onAppear {
            if !AppStartTracker.shared.finished { // 避免多次 onAppear
                AppStartTracker.shared.finished = true
                let cost = Int(Double(Date().timeIntervalSince1970 - AppStartTracker.shared.launchTime) * 1000.0)
                log("主界面加载完成, App 启动总耗时 \(cost)ms")
            }
        }
    }
    
    private func createViewFromRouter() -> some View {
        VStack(spacing: 0) {
            Group {
                if dataManager.router.getLast().isRoot {
                    TitleBarView()
                } else {
                    SubviewTitleBarView()
                }
            }
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color("BackgroundColor"))
                    .shadow(radius: 2)
                    .frame(width: dataManager.leftTabWidth)
                    .overlay(
                        dataManager.leftTabContent
                            .scaleEffect(isLeftTabVisible ? 1 : 0.96, anchor: .center)
                            .opacity(isLeftTabVisible ? 1 : 0)
                            .onChange(of: dataManager.leftTabId) {
                                isLeftTabVisible = false
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                    isLeftTabVisible = true
                                }
                            }
                    )
                AnyView(dataManager.router.getLastView())
                    .foregroundStyle(Color("TextColor"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AppSettings.shared.theme.getBackgroundStyle())
        }
        .frame(minWidth: 700, minHeight: 420)
    }
}

#Preview {
    ContentView()
}

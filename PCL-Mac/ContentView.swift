//
//  ContentView.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/5/17.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    
    @State private var isLeftTabVisible: Bool = true
    
    var body: some View {
        ZStack {
            createViewFromRouter()
            if let tasks = dataManager.inprogressInstallTasks {
                if case .installing = dataManager.router.getLast() {
                    EmptyView()
                } else {
                    HStack() {
                        Spacer()
                        VStack() {
                            Spacer()
                            RoundedButton {
                                Image("DownloadItem")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20)
                            } onClick: {
                                dataManager.router.append(.installing(tasks: tasks))
                            }
                            .padding()
                        }
                    }
                }
            }
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    HintOverlay()
                    Spacer()
                }
                .padding(.bottom, 50)
            }
            if let currentPopup = dataManager.currentPopup {
                Group {
                    Rectangle()
                        .fill(currentPopup.type.getMaskColor())
                    currentPopup
                        .padding()
                }
            }
        }
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
            if dataManager.router.getLast().isRoot {
                TitleBarComponent()
            } else {
                SubviewTitleBarComponent()
            }
            HStack {
                ZStack {
                    Rectangle()
                        .fill(Color("BackgroundColor"))
                        .shadow(radius: 2)
                    dataManager.leftTabContent
                        .scaleEffect(isLeftTabVisible ? 1 : 0.9 , anchor: .center)
                        .opacity(isLeftTabVisible ? 1 : 0)
                        .onChange(of: dataManager.leftTabId) { _ in
                            isLeftTabVisible = false
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                isLeftTabVisible = true
                            }
                        }
                }
                .frame(width: dataManager.leftTabWidth)
                .zIndex(1)
                .animation(.easeInOut(duration: 0.05), value: dataManager.leftTabWidth)
                
                AnyView(dataManager.router.getLastView())
                    .foregroundStyle(Color("TextColor"))
                    .frame(minWidth: 815 - dataManager.leftTabWidth, minHeight: 418)
                    .zIndex(0)
            }
            .background(
                AppSettings.shared.theme.getBackgroundView()
            )
            .overlay {
                if SharedConstants.shared.isDevelopment {
                    VStack {
                        HStack {
                            Text(dataManager.router.getDebugText())
                                .font(.custom("PCL English", size: 14))
                                .foregroundStyle(Color("TextColor"))
                                .animation(.easeInOut(duration: 0.2), value: dataManager.router.path)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }
    
    static func setPopup(_ popup: PopupOverlay?) {
        DispatchQueue.main.async {
            if popup != nil {
                NSApp.windows.forEach { $0.isMovableByWindowBackground = true }
                DataManager.shared.popupState = .beforePop
            } else {
                NSApp.windows.forEach { $0.isMovableByWindowBackground = false }
            }
            DataManager.shared.currentPopup = popup
        }
    }
}

#Preview {
    ContentView()
}

//
//  PopupManager.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/10/25.
//

import SwiftUI

@MainActor
class PopupManager: ObservableObject {
    public static let shared: PopupManager = .init()
    
    @Published var currentPopup: PopupModel?
    @Published var popupState: PopupAnimationState = .beforePop
    private var callback: ((Int) -> Void)?
    
    func showAsync(_ popup: PopupModel) async -> Int {
        NSApp.windows.forEach { $0.isMovableByWindowBackground = true }
        self.popupState = .beforePop
        self.currentPopup = popup
        return await withCheckedContinuation { continuation in
            self.callback = { continuation.resume(returning: $0) }
        }
    }
    
    func show(_ popup: PopupModel, callback: ((Int) -> Void)? = nil) {
        NSApp.windows.forEach { $0.isMovableByWindowBackground = true }
        self.popupState = .beforePop
        self.currentPopup = popup
        self.callback = callback
    }
    
    func clear() {
        NSApp.windows.forEach { $0.isMovableByWindowBackground = false }
        self.currentPopup = nil
    }
    
    func onClick(id: UUID) {
        if let currentPopup {
            self.callback?(currentPopup.buttons.firstIndex(where: { $0.id == id }) ?? 0)
            self.callback = nil
            self.popupState = .afterCollapse
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.currentPopup = nil
            }
        }
    }
    
    private init() {}
}

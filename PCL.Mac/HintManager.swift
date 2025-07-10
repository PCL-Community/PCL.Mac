//
//  HintManager.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/26.
//

import SwiftUI

class HintManager: ObservableObject {
    public static let `default`: HintManager = .init()
    
    @Published var hints: [Hint] = []
    
    func add(_ hint: Hint) {
        DispatchQueue.main.async {
            withAnimation(.linear(duration: 0.2)) {
                self.hints.append(hint)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.remove(hint)
            }
        }
    }
    
    private func remove(_ hint: Hint) {
        if let idx = self.hints.firstIndex(of: hint) {
            var _ = withAnimation {
                self.hints.remove(at: idx)
            }
        }
    }
}

func hint(_ text: String, _ type: HintType = .info) {
    HintManager.default.add(.init(text: text, type: type))
}

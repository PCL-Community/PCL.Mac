//
//  ViewExtension.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/19.
//

import SwiftUI

struct AnimationCompletionModifier<Value: VectorArithmetic>: AnimatableModifier {
    var animatableData: Value {
        didSet { checkCompletion() }
    }
    let targetValue: Value
    let completion: () -> Void

    func checkCompletion() {
        if animatableData == targetValue {
            DispatchQueue.main.async { completion() }
        }
    }

    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func onAnimationCompleted<Value: VectorArithmetic>(
        for value: Value,
        completion: @escaping () -> Void
    ) -> some View {
        modifier(AnimationCompletionModifier(
            animatableData: value,
            targetValue: value,
            completion: completion
        ))
    }
}

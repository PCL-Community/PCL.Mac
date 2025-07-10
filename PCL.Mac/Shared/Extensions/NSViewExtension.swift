//
//  NSViewExtension.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/18.
//

import SwiftUI

extension NSView {
    func addDragGesture() {
        let pan = NSPanGestureRecognizer(target: self, action: #selector(handleDrag(_:)))
        self.addGestureRecognizer(pan)
    }
    
    @objc func handleDrag(_ sender: NSPanGestureRecognizer) {
        guard let window = self.window else { return }
        let location = sender.translation(in: nil)
        window.setFrameOrigin(CGPoint(
            x: window.frame.origin.x + location.x,
            y: window.frame.origin.y - location.y
        ))
        sender.setTranslation(.zero, in: nil)
    }
}

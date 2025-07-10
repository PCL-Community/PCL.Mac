//
//  NSPointExtension.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/18.
//

import SwiftUI

extension NSPoint {
    func distance(to point: NSPoint) -> CGFloat {
        let dx = self.x - point.x
        let dy = self.y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}

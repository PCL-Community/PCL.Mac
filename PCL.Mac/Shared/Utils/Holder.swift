//
//  Holder.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/30.
//

import SwiftUI
import Combine

final class Holder<T: ObservableObject>: ObservableObject {
    @Published var object: T?
    
    init(object: T? = nil) {
        self.object = object
    }
    
    func setObject(_ newObject: T?) {
        self.object = newObject
    }
    
    func modifyObject(_ modify: (T) -> Void) {
        if let obj = object {
            modify(obj)
            objectWillChange.send()
        }
    }
}

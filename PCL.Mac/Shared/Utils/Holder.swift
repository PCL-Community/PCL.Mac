//
//  Holder.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/30.
//

import SwiftUI
import Combine

final class Holder<T>: ObservableObject {
    @Published var object: T?
    
    init(object: T? = nil) {
        self.object = object
    }
    
    func setObject(_ newObject: T?) {
        DispatchQueue.main.async {
            self.object = newObject
            self.objectWillChange.send()
        }
    }
    
    func modifyObject(_ modify: @escaping (T) -> Void) {
        DispatchQueue.main.async {
            if let obj = self.object {
                modify(obj)
                self.objectWillChange.send()
            }
        }
    }
}

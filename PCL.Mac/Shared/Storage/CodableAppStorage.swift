//
//  CodableAppStorage.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/3.
//

import Foundation

@propertyWrapper
public struct CodableAppStorage<T: Codable> {
    private let key: String
    private let store: UserDefaults
    private let defaultValue: T

    public var wrappedValue: T {
        get {
            if let data = store.data(forKey: key),
               let decoded = try? JSONDecoder().decode(T.self, from: data) {
                return decoded
            } else {
                return defaultValue
            }
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                store.set(data, forKey: key)
            }
            DispatchQueue.main.async {
                DataManager.shared.objectWillChange.send()
            }
        }
    }

    public init(wrappedValue: T, _ key: String, store: UserDefaults = .standard) {
        self.key = key
        self.store = store
        self.defaultValue = wrappedValue
        // 初始写入（仅当没有值时）
        if store.data(forKey: key) == nil,
           let data = try? JSONEncoder().encode(wrappedValue) {
            store.set(data, forKey: key)
        }
    }
}

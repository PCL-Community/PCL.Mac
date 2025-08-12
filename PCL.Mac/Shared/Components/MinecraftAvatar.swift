//
//  MinecraftAvatar.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/30.
//

import SwiftUI
import CoreGraphics

struct MinecraftAvatar: View {
    @State private var skinData: Data?
    
    private let account: AnyAccount
    private let src: String
    private let size: CGFloat

    init(account: AnyAccount, src: String, size: CGFloat = 58) {
        self.account = account
        self.src = src
        self.size = size
        if let cached = SkinCacheStorage.shared.skinCache[account.uuid] {
            self._skinData = State(initialValue: cached)
        }
    }

    var body: some View {
        ZStack {
            if let data = skinData {
                SkinLayerView(imageData: data, startX: 8, startY: 16, width: 8 * 5.4 / 58 * size, height: 8 * 5.4 / 58 * size)
                    .shadow(color: Color.black.opacity(0.2), radius: 1)
                SkinLayerView(imageData: data, startX: 40, startY: 16, width: 7.99 * 6.1 / 58 * size, height: 7.99 * 6.1 / 58 * size)
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .padding(6)
        .task {
            if skinData == nil {
                do {
                    self.skinData = try await SkinCacheStorage.shared.loadSkin(account: account)
                } catch {
                    err("无法加载头像: \(error.localizedDescription)")
                }
            }
        }
    }
}

fileprivate struct SkinLayerView: View {
    let imageData: Data
    let startX: CGFloat
    let startY: CGFloat
    let width: CGFloat
    let height: CGFloat
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: width, height: height)
            } else {
                Color.clear
            }
        }
        .onAppear {
            if var image = CIImage(data: imageData) {
                let yOffset: CGFloat = image.extent.height == 32 ? 0 : 32
                image = image.cropped(to: CGRect(x: startX, y: startY + yOffset, width: 8, height: 8))
                let context = CIContext(options: nil)
                let extent = image.extent
                guard let cgImage = context.createCGImage(image, from: extent) else { return }
                self.image = NSImage(cgImage: cgImage, size: image.extent.size)
            } else {
                err("无法获取头像")
            }
        }
    }
}

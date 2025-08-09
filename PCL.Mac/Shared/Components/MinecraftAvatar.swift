//
//  MinecraftAvatar.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/30.
//

import SwiftUI
import CoreGraphics

enum AvatarInputType {
    case username, uuid, url
}

struct MinecraftAvatar: View {
    private static var skinCache: [String: Data] = [:]
    private static var loadingKeys: Set<String> = []

    let type: AvatarInputType
    let src: String
    let size: CGFloat

    @State private var imageData: Data?

    init(type: AvatarInputType, src: String, size: CGFloat = 58) {
        self.type = type
        self.src = src
        self.size = size
        self._imageData = State(initialValue: Self.skinCache[src])
    }

    private var skinURL: URL {
        switch type {
        case .username:
            return URL(string: "https://minotar.net/skin/\(src)")!
        case .uuid:
            return URL(string: "https://crafatar.com/skins/\(src)")!
        case .url:
            return URL(string: src)!
        }
    }

    var body: some View {
        ZStack {
            if let data = imageData {
                SkinLayerView(imageData: data, startX: 8, startY: 16, width: 8 * 5.4 / 58 * size, height: 8 * 5.4 / 58 * size)
                    .shadow(color: Color.black.opacity(0.2), radius: 1)
                SkinLayerView(imageData: data, startX: 40, startY: 16, width: 7.99 * 6.1 / 58 * size, height: 7.99 * 6.1 / 58 * size)
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .padding(6)
        .task { await loadIfNeeded() }
    }

    private func loadIfNeeded() async {
        if imageData != nil { return }
        if let cached = Self.skinCache[src] {
            imageData = cached
            return
        }
        if Self.loadingKeys.contains(src) { return }
        Self.loadingKeys.insert(src)
        defer { Self.loadingKeys.remove(src) }

        if let data = await Requests.get(skinURL).data {
            await MainActor.run {
                Self.skinCache[src] = data
                self.imageData = data
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

#Preview {
    MinecraftAvatar(type: .username, src: "MinecraftVenti")
}

//
//  MinecraftAvatarComponent.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/30.
//

import SwiftUI
import CoreGraphics

enum AvatarInputType {
    case username, uuid, url
}

struct MinecraftAvatarComponent: View {
    let type: AvatarInputType
    let src: String
    private(set) var size: CGFloat = 58
    
    @State private var imageData: Data?

    var skinUrl: URL {
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
                    .shadow(color: Color.black.opacity(0.15), radius: 1.4, x: 0, y: 1.1)
                SkinLayerView(imageData: data, startX: 40, startY: 16, width: 7.99 * 6.1 / 58 * size, height: 7.99 * 6.1 / 58 * size)
            }
        }
        .onAppear {
            Task {
                if let data = await Requests.get(skinUrl).data {
                    DispatchQueue.main.async {
                        self.imageData = data
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .padding(6)
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
    MinecraftAvatarComponent(type: .username, src: "MinecraftVenti")
}

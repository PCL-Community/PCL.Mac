//
//  MinecraftAvatarComponent.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/6/30.
//

import SwiftUI
import CoreGraphics
import Alamofire

enum AvatarInputType {
    case username, uuid, url
}

struct MinecraftAvatarComponent: View {
    let type: AvatarInputType
    let src: String
    
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
                SkinLayerView(imageData: data, startX: 8, startY: 16, width: 8, height: 8)
                    .scaleEffect(5.4)
                    .shadow(color: Color.black.opacity(0.2), radius: 1)
                SkinLayerView(imageData: data, startX: 40, startY: 16, width: 7.99, height: 7.99)
                    .scaleEffect(6.1)
            }
        }
        .onAppear {
            AF.request(skinUrl)
                .response { response in
                    self.imageData = response.data
                }
        }
        .frame(width: 58, height: 58)
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
                Color.gray
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

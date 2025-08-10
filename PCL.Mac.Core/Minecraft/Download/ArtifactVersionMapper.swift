//
//  ArtifactVersionMapperV2.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/6/14.
//

import Foundation

public struct ArtifactVersionMapper {
    public static func map(_ manifest: ClientManifest, arch: Architecture = .system) {
        if arch != .arm64 {
            for (library, _) in manifest.getNeededNatives() {
                library.name = "org.lwjgl:\(library.artifactId):3.3.2:natives-macos"
            }
            return
        }
        
        // 避免因 LWJGL 版本不对导致的无法启动
        // 以下条件通过代表使用 -cp 方式添加本地库，这种方式一定会有 natives-macos-arm64，无需更改就能启动游戏
        // 未通过则大概率没有写 arm64 架构的本地库 (例如 1.18.2)
        // 懒得开 Issue，所以写这吧 awa
        if manifest.getNeededNatives().isEmpty {
            return
        }
        
        // MARK: - 替换依赖项版本
        for library in manifest.getNeededLibraries() {
            switch library.groupId {
            case "org.lwjgl":
                if library.version.starts(with: "3.") && library.version != "3.3.3" {
                    changeVersion(library, "3.3.2")
                }
                library.artifact?.url = "https://libraries.minecraft.net/\(Util.toPath(mavenCoordinate: library.name))"
            
            case "net.java.dev.jna":
                if library.version == "4.4.0" {
                    changeVersion(library, "5.14.0")
                }
                library.artifact?.url = "https://libraries.minecraft.net/\(Util.toPath(mavenCoordinate: library.name))"
            case "ca.weblite":
                if library.artifactId == "java-objc-bridge" {
                    library.name = "org.glavo.hmcl.mmachina:java-objc-bridge:1.1.0-mmachina.1"
                    library.artifact?.url = "https://repo1.maven.org/maven2/\(Util.toPath(mavenCoordinate: library.name))"
                }
            default:
                continue
            }
            
            library.artifact?.path = Util.toPath(mavenCoordinate: library.name)
        }
        
        // MARK: - 替换本地库版本
        for (library, artifact) in manifest.getNeededNatives() {
            switch library.groupId {
            case "org.lwjgl":
                if library.version.starts(with: "3.") && library.version != "3.3.3" {
                    changeVersion(library, "3.3.2")
                }
                library.name = "org.lwjgl:\(library.artifactId):3.3.2:natives-macos-arm64"
                artifact.url = "https://libraries.minecraft.net/org/lwjgl/\(library.artifactId)/\(library.version)/\(library.artifactId)-\(library.version)-natives-macos-arm64.jar"
            case "org.lwjgl.lwjgl":
                if library.artifactId == "lwjgl-platform" {
                    library.name = "org.glavo.hmcl:lwjgl2-natives:2.9.3-rc1-osx-arm64"
                    artifact.url = "https://repo1.maven.org/maven2/org/glavo/hmcl/lwjgl2-natives/2.9.3-rc1-osx-arm64/lwjgl2-natives-2.9.3-rc1-osx-arm64.jar"
                    artifact.path = "org/glavo/hmcl/lwjgl2-natives/2.9.3-rc1-osx-arm64/lwjgl2-natives-2.9.3-rc1-osx-arm64.jar"
                    continue
                }
            case "ca.weblite":
                if library.artifactId == "java-objc-bridge" {
                    library.name = "org.glavo.hmcl.mmachina:java-objc-bridge:1.1.0-mmachina.1"
                    artifact.url = "https://repo1.maven.org/maven2/org/glavo/hmcl/mmachina/java-objc-bridge/1.1.0-mmachina.1/java-objc-bridge-1.1.0-mmachina.1.jar"
                    artifact.path = "org/glavo/hmcl/mmachina/java-objc-bridge/1.1.0-mmachina.1/java-objc-bridge-1.1.0-mmachina.1.jar"
                    continue
                }
            default:
                continue
            }
            
            artifact.path = URL(string: artifact.url)!.path
        }
    }
    
    private static func changeVersion(_ library: ClientManifest.Library, _ newVersion: String) {
        library.name = library.name.replacingOccurrences(of: library.version, with: newVersion)
    }
}

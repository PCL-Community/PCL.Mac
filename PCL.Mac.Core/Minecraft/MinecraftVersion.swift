//
//  MinecraftVersion.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/23.
//

import Foundation

public class MinecraftVersion: Comparable, Hashable {
    public let displayName: String
    public let type: VersionType
    private var _releaseDate: Date?
    public var releaseDate: Date {
        if _releaseDate == nil {
            _releaseDate = VersionManifest.getReleaseDate(self)
        }
        return _releaseDate ?? Date(timeIntervalSince1970: TimeInterval(0))
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(displayName)
    }
    
    public init(displayName: String, type: VersionType? = nil) {
        self.displayName = displayName
        self.type = type ?? .parse(displayName)
    }
    
    public static func < (lhs: MinecraftVersion, rhs: MinecraftVersion) -> Bool {
        lhs.releaseDate < rhs.releaseDate
    }
    
    public static func == (lhs: MinecraftVersion, rhs: MinecraftVersion) -> Bool {
        lhs.displayName == rhs.displayName && lhs.type == rhs.type
    }
    
    public func getIconName() -> String {
        switch type {
        case .release: "ReleaseVersionIcon"
        case .snapshot, .pending: "SnapshotVersionIcon"
        case .beta, .alpha: "OldVersionIcon"
        case .aprilFool: "AprilFoolVersionIcon"
        default: "ReleaseVersionIcon"
        }
    }
}

public enum VersionType: String {
    case release = "release"
    case snapshot = "snapshot"
    case prerelease = "pre-release"
    case rc = "rc"
    case alpha = "old_alpha"
    case beta = "old_beta"
    case aprilFool = "april_fool"
    case pending = "pending"
    
    public static func parse(_ displayVersion: String) -> VersionType {
        guard let manifest = DataManager.shared.versionManifest else {
            err("版本清单加载时机错误，请将此问题报告给开发者")
            return .release
        }
        
        guard let version = manifest.versions.find({ $0.id == displayVersion }) else {
            return .release
        }
        
        return .init(rawValue: version.type) ?? .release
    }
}

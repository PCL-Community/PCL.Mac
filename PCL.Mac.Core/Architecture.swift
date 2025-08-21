//
//  Architecture.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/11/25.
//

import Foundation

public enum Architecture {
    public static var system: Architecture {
        get {
            if _systemArch == nil {
                var systemInfo = utsname()
                uname(&systemInfo)
                let machineMirror = Mirror(reflecting: systemInfo.machine)
                let identifier = machineMirror.children.reduce("") { identifier, element in
                    guard let value = element.value as? Int8, value != 0 else { return identifier }
                    return identifier + String(UnicodeScalar(UInt8(value)))
                }
                _systemArch = (identifier == "arm64" ? .arm64 : .x64)
            }
            return _systemArch!
        }
    }
    
    public static func getArchOfFile(_ executableURL: URL) -> Architecture {
        guard let fh = try? FileHandle(forReadingFrom: executableURL) else { return .unknown }
        defer { try? fh.close() }
        
        guard let magicData = try? fh.read(upToCount: 4), magicData.count == 4 else { return .unknown }
        let magic = magicData.withUnsafeBytes { $0.load(as: UInt32.self) }
        let isFat = (magic == 0xBEBAFECA || magic == 0xBFBAFECA || magic == 0xCAFEBABE || magic == 0xCAFEBABF)
        
        if isFat {
            guard let nfatArchData = try? fh.read(upToCount: 4), nfatArchData.count == 4 else { return .unknown }
            let nfatArch = nfatArchData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            
            var foundX64 = false
            var foundArm64 = false
            
            for _ in 0..<nfatArch {
                guard let archData = try? fh.read(upToCount: 20), archData.count == 20 else { return .unknown }
                let cputype = archData.prefix(4).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
                switch cputype {
                case 0x1000007: foundX64 = true // CPU_TYPE_X86_64
                case 0x100000C: foundArm64 = true // CPU_TYPE_ARM64
                default: break
                }
            }
            if foundX64 && foundArm64 {
                return .fatFile
            } else if foundArm64 {
                return .arm64
            } else if foundX64 {
                return .x64
            } else {
                return .unknown
            }
        }
        
        guard let cputypeData = try? fh.read(upToCount: 4), cputypeData.count == 4 else { return .unknown }
        let cputype = cputypeData.withUnsafeBytes { $0.load(as: UInt32.self) }
        switch cputype {
        case 0x100000C: return .arm64
        case 0x1000007: return .x64
        default: return .unknown
        }
    }
    
    private static var _systemArch: Architecture? = nil
    /// ARM64，Apple Silicon
    case arm64
    
    /// x86_64，Intel Chip
    case x64
    
    /// Universal Binary，至少包含 ARM64 与 x86_64
    case fatFile
    
    /// 未知
    case unknown
    
    /// 是否与某个架构兼容。
    /// - Parameter arch: 目标架构，不可为 fatFile
    public func isCompatiable(with arch: Architecture) -> Bool {
        return self == arch || self == .fatFile
    }
    
    /// 是否与系统架构兼容。
    public func isCompatiableWithSystem() -> Bool {
        return isCompatiable(with: .system)
    }
    
    public static func fromString(_ string: String) -> Architecture {
        switch string {
        case "aarch64", "arm64", "arm": .arm64
        case "x86", "x64", "x86_64", "amd64": .x64
        default: .unknown
        }
    }
}

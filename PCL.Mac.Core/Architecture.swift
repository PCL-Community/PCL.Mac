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
        
        if magic == 0xBEBAFECA || magic == 0xBFBAFECA {
            return .fatFile
        }
        
        guard let cputypeData = try? fh.read(upToCount: 4), cputypeData.count == 4 else { return .unknown }
        let cputype = cputypeData.withUnsafeBytes { $0.load(as: UInt32.self) }

        switch cputype {
        case 0x1000007: return .x64
        case 0x100000C: return .arm64
        default: return .unknown
        }
    }
    
    private static var _systemArch: Architecture? = nil
    case arm64, x64, fatFile, unknown
    
    public static func fromString(_ string: String) -> Architecture {
        switch string {
        case "aarch64", "arm64", "arm": .arm64
        case "x86", "x64", "x86_64", "amd64": .x64
        default: .unknown
        }
    }
}

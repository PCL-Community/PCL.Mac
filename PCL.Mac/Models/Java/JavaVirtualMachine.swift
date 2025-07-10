//
//  JavaEntity.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/5/18.
//

import Foundation

public class JavaVirtualMachine: Identifiable, Equatable {
    static let Error = JavaVirtualMachine(arch: .unknown, version: -1, displayVersion: "错误", executableUrl: URL(fileURLWithPath: "Error"), callMethod: .incompatible, _isError: true)
    
    public let arch: ExecArchitectury
    public var version: Int
    public var displayVersion: String
    public var implementor: String?
    public let executableUrl: URL
    public let callMethod: CallMethod
    public let isJdk: Bool?
    public var isError: Bool {
        get {
            return _isError ?? false
        }
    }
    public var isAddedByUser: Bool {
        get {
            return _isAddedByUser ?? false
        }
    }
    private var _isError: Bool?
    private var _isAddedByUser: Bool?
    
    public let id = UUID()
    
    public init(arch: ExecArchitectury, version: Int, displayVersion: String, implementor: String? = nil, executableUrl: URL, callMethod: CallMethod, isJdk: Bool? = nil, _isError: Bool? = nil, _isAddedByUser: Bool? = nil) {
        self.arch = arch
        self.version = version
        self.displayVersion = displayVersion
        self.implementor = implementor
        self.executableUrl = executableUrl
        self.callMethod = callMethod
        self.isJdk = isJdk
        self._isError = _isError
        self._isAddedByUser = _isAddedByUser
    }
    
    func getTypeLabel() -> String {
        guard let isJdk = isJdk else {
            return "Java"
        }
        return isJdk ? "JDK" : "JRE"
    }
    
    private func asyncDetectVersion() async {
        (version, displayVersion) = JavaVirtualMachine.detectVersion(url: executableUrl)
    }
    
    public static func of(_ executableUrl: URL, _ addedByUser: Bool? = nil) -> JavaVirtualMachine {
        // 判断文件是否合法
        guard FileManager.default.fileExists(atPath: executableUrl.path) else {
            err("\(executableUrl) not found!")
            return Error
        }
        guard executableUrl.isFileURL else {
            err("\(executableUrl.path()) 不是文件!")
            return Error
        }
        
        // 设置架构及调用方式
        let arch: ExecArchitectury = .getArchOfFile(executableUrl)
        let callMethod: CallMethod?
        if arch == ExecArchitectury.SystemArch || arch == .fatFile {
            callMethod = .direct
        } else if ExecArchitectury.SystemArch == .arm64 {
            callMethod = .transition
        } else {
            callMethod = .incompatible
        }
        
        // 获取版本信息
        let releaseUrls = [
            executableUrl.parent().parent().appending(path: "release"),
            executableUrl.parent().parent().parent().appending(path: "release")
        ]
        var version: Int = 0
        var displayVersion: String = "未知"
        var asyncDetect: Bool = true
        var implementor: String?
        
        for releaseUrl in releaseUrls {
            if FileManager.default.fileExists(atPath: releaseUrl.path) {
                let release = PropertiesParser.parse(fileUrl: releaseUrl)
                if let javaVersion = release["JAVA_VERSION"] {
                    displayVersion = javaVersion
                    version = Int(displayVersion.split(separator: ".")[displayVersion.starts(with: "1.") ? 1 : 0])!
                } else {
                    err("加载 \(executableUrl.path()) 时出现错误: 未找到键 JAVA_VERSION 对应的值")
                }
                implementor = release["IMPLEMENTOR"]
                asyncDetect = false
                break
            }
        }
        
        // 检查是否为 JDK
        var isJdk: Bool? = nil
        if executableUrl.path != "/usr/bin/java" {
            if FileManager.default.fileExists(atPath: executableUrl.parent().appending(path: "javac").path) {
                isJdk = true
            } else {
                isJdk = false
            }
        }
        
        let jvm = JavaVirtualMachine(arch: arch, version: version, displayVersion: displayVersion, implementor: implementor, executableUrl: executableUrl, callMethod: callMethod ?? .incompatible, isJdk: isJdk, _isAddedByUser: addedByUser)
        if asyncDetect {
            Task {
                await jvm.asyncDetectVersion()
            }
        }
        return jvm
    }
    
    private static func detectVersion(url: URL) -> (version: Int, displayVersion: String) {
        do {
            let process = Process()
            process.executableURL = url
            process.arguments = ["-version"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                throw NSError(domain: "JavaVersionDetector", code: 1, userInfo: [NSLocalizedDescriptionKey: "Output decoding failed"])
            }
            
            let versionPattern = #"(?:openjdk|java)\s+version\s+"([0-9]{1,3}(?:[\.\-\+][\w\.\+]+)?)""#
            let regex = try NSRegularExpression(pattern: versionPattern, options: .caseInsensitive)
            if let match = regex.firstMatch(in: output, options: [], range: NSRange(location: 0, length: output.utf16.count)),
                let range = Range(match.range(at: 1), in: output) {
                let displayVersion = String(output[range])
            
                let majorVersionString = displayVersion.split(separator: ".").first?.split(separator: "-").first ?? ""
                if let majorVersion = Int(majorVersionString) {
                    return (majorVersion, displayVersion)
                }
            }
            throw NSError(domain: "JavaVersionDetector", code: 2, userInfo: [NSLocalizedDescriptionKey: "\(url.path) 中的 Java 版本未找到"])
        } catch {
            err("无法检测 java 版本: \(error.localizedDescription)")
        }
        return (0, "未知")
    }
    
    public static func == (jvm1: JavaVirtualMachine, jvm2: JavaVirtualMachine) -> Bool {
        return jvm1.executableUrl == jvm2.executableUrl
    }
}

public enum ExecArchitectury {
    public static var SystemArch: ExecArchitectury {
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
    
    public static func getArchOfFile(_ executableUrl: URL) -> ExecArchitectury {
        guard let fh = try? FileHandle(forReadingFrom: executableUrl) else { return .unknown }
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
    
    private static var _systemArch: ExecArchitectury? = nil
    case arm64, x64, fatFile, unknown
}

public enum CallMethod {
    case direct, transition, incompatible
    func getDisplayName() -> String {
        switch self {
        case .direct: "直接运行"
        case .transition: "转译"
        case .incompatible: "不兼容"
        }
    }
}

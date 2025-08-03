# PCL.Mac 🖥️

<div align="center">
  <img alt="Logo" src="/.github/assets/icon.png" width="256">
  
  [![QQ Group](https://img.shields.io/badge/QQ群-1047463389-blue)](https://jq.qq.com/?_wv=1027&k=5X6X9X8X)
  [![Platform](https://img.shields.io/badge/macOS-13.0+-blue)](https://developer.apple.com/macos/)
  [![](https://hits.zkitefly.eu.org/?tag=https://github.com/PCL-Community/PCL.Mac)](https://hits.zkitefly.eu.org/?tag=https://github.com/PCL-Community/PCL.Mac&web=true)
  
</div>

## 简介

> SwiftUI 重构的 macOS 版 [PCL2](https://github.com/Hex-Dragon/PCL2)（作者：龙腾猫跃），追求更快、更好、更强。<br>
> 我们 macOS 也要有自己的 Minecraft 启动器！<br>

本项目使用了 [PCL-Community/glfw-patcher](https://github.com/PCL-Community/glfw-patcher) ，用于在本地自动 patch LWJGL 的 `lwjgl-glfw.jar`，以解决兼容性问题。<br>

## 下载

因本项目还在早期开发阶段，所以没有 Release。你可以从 [Actions](https://github.com/PCL-Community/PCL.Mac/actions) 中下载早期开发版本。<br>
> [!WARNING]
> 因 App 未签名，所以你需要进入终端，然后输入：<br>
> ```bash
> sudo spctl --master-disable
> ```
> 输入正确的密码，然后进入`设置 > 隐私与安全性 > 安全性`，将「允许以下来源的应用程序」改为「任何来源」。<br>
> ~~若您认为可能造成安全性问题，请每年V我们七百块钱来签名。~~

## 分片下载器

本启动器启动后静默下载 [aria2](https://github.com/aria2/aria2) 作为外部分片下载器，提升下载性能。

已集成的 aria2 Universal Binary 由 [Gitee 仓库](https://gitee.com/yizhimcqiu/aria2-macos-universal) 提供，支持 macOS x86_64 和 arm64 架构。

> aria2 遵循 GPL v2 协议，具体见 [LICENSE](https://gitee.com/yizhimcqiu/aria2-macos-universal/blob/master/COPYING)。
> 本项目仅分发第三方二进制，非官方编译版本。如需官方源码与说明，请访问 [aria2 项目主页](https://github.com/aria2/aria2)。

## 兼容性

需要 **macOS 13.0+** 才能运行本 App。

## 鸣谢

- FUNCTY
- [AMagicPear](https://github.com/AMagicPear)
- [Glavo](https://github.com/Glavo)
- [HMCL-Dev](https://github.com/HMCL-Dev)
- [Copilot](https://github.com/copilot)[ (?](https://www.bilibili.com/video/BV1GJ411x7h7)
- [aria2](https://github.com/aria2/aria2) 项目及其开发者

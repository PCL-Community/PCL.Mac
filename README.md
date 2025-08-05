# PCL.Mac 🖥️

<div align="center">
  <img alt="Logo" src="/.github/assets/icon.png" width="180">

  [![QQ 群 1047463389](https://img.shields.io/badge/QQ群-1047463389-blue)](https://jq.qq.com/?_wv=1027&k=5X6X9X8X)
  [![最低平台 macOS 13+](https://img.shields.io/badge/macOS-13.0+-blue)](https://developer.apple.com/macos/)
  [![](https://hits.zkitefly.eu.org/?tag=https://github.com/PCL-Community/PCL.Mac)](https://hits.zkitefly.eu.org/?tag=https://github.com/PCL-Community/PCL.Mac&web=true)
</div>

## 简介

SwiftUI 重构的 macOS 版 [PCL2](https://github.com/Hex-Dragon/PCL2)，追求更快、更好、更强。  
让 macOS 也拥有自己的 Minecraft 启动器！

## 下载

本项目尚处早期开发阶段，可从 [Actions](https://github.com/PCL-Community/PCL.Mac/actions) 下载开发版。

> [!WARNING]
> 由于 App 未签名，请在终端运行：
> ```bash
> sudo spctl --master-disable
> ```
> 之后在「设置 → 隐私与安全性」允许「任何来源」的应用。  
> ~~若你认为可能降低安全性，请每年 V 我们 700 块钱来签名~~

## 分片下载加速

启动器会自动下载 [aria2](https://github.com/aria2/aria2) 作为分片下载器，提升下载速度。  
已集成的 Universal Binary 由 [Gitee 仓库](https://gitee.com/yizhimcqiu/aria2-macos-universal) 提供，支持 x86_64 和 arm64。

> aria2 遵循 GPL v2 协议，详情见 [LICENSE](https://gitee.com/yizhimcqiu/aria2-macos-universal/blob/master/COPYING)。  
> 本项目分发第三方二进制，非官方编译。如需源码请访问 [aria2 项目主页](https://github.com/aria2/aria2)。

## 兼容性

仅支持 **macOS 13.0 及以上**。

## 鸣谢

- FUNCTY
- [AMagicPear](https://github.com/AMagicPear)
- [Glavo](https://github.com/Glavo)
- [HMCL-Dev](https://github.com/HMCL-Dev)
- [Copilot](https://github.com/copilot)
- [aria2](https://github.com/aria2/aria2)

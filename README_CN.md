# ClipboardManager

一个轻量级的 macOS 菜单栏剪切板历史管理工具，灵感来自 Windows 内置的剪切板历史功能（Win+V）。

[English](README.md)

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 功能特性

- **剪切板历史** — 自动保存最近 50 条复制的文本内容
- **全局快捷键** — 按 `⌘⇧V` 即可呼出剪切板面板
- **不抢焦点的浮动面板** — 面板不会从活跃输入框抢走焦点
- **智能定位** — 面板自动出现在当前聚焦输入框附近，像 Windows 剪切板一样
- **连续粘贴** — 粘贴后面板保持打开，可依次粘贴多条内容
- **菜单栏驻留** — 安静地住在菜单栏，不占用 Dock
- **一键粘贴** — 点击任意历史条目自动粘贴到当前应用
- **搜索过滤** — 快速在历史记录中搜索内容
- **自动去重** — 重复内容自动移到最顶部
- **持久化存储** — 重启应用后历史记录依然保留
- **原生体验** — 基于 Swift & SwiftUI 构建，轻量流畅

## 界面预览

```
┌─────────────────────────────┐
│  Clipboard History   Clear All │
├─────────────────────────────┤
│  🔍 搜索...                    │
├─────────────────────────────┤
│  你好，世界                    │
│  2 分钟前                   ✕  │
├─────────────────────────────┤
│  https://github.com            │
│  5 分钟前                   ✕  │
├─────────────────────────────┤
│  func example() { ... }       │
│  1 小时前                   ✕  │
└─────────────────────────────┘
```

## 系统要求

- macOS 13.0 (Ventura) 及以上
- 辅助功能权限（用于全局快捷键和自动粘贴）

## 安装方式

### 从源码编译

```bash
git clone https://github.com/LonelySnow1/ClipboardManager.git
cd ClipboardManager
swift build -c release
```

编译产物位于 `.build/release/ClipboardManager`。

### 直接运行

```bash
swift run
```

也可以将二进制文件复制到 `/Applications` 目录以便日常使用。

## 首次使用配置

首次启动时，需要授予**辅助功能**权限：

1. 打开 **系统设置 → 隐私与安全性 → 辅助功能**
2. 点击 `+` 按钮，添加 `ClipboardManager`
3. 重启应用

该权限用于：
- 全局快捷键 `⌘⇧V` 在任意应用中生效
- 选中条目后自动模拟 `⌘V` 完成粘贴
- 通过 Accessibility API 读取聚焦输入框位置

## 使用方法

| 操作 | 方式 |
|------|------|
| 呼出剪切板面板 | 点击菜单栏图标 或 按 `⌘⇧V` |
| 粘贴历史条目 | 点击对应条目 |
| 连续粘贴多条 | 持续点击 — 面板保持打开 |
| 删除某条记录 | 鼠标悬停后点击 `✕` |
| 搜索历史记录 | 在搜索框中输入关键词 |
| 清空所有记录 | 点击右上角 "Clear All" |
| 打开设置 | 右键菜单栏图标 → Settings |

## 项目结构

```
├── Package.swift
├── README.md
├── README_CN.md
└── ClipboardManager/
    ├── ClipboardManagerApp.swift       # App 入口 & 浮动面板定位逻辑
    ├── Models/
    │   └── ClipboardItem.swift         # 数据模型
    ├── Services/
    │   ├── ClipboardMonitor.swift      # 剪切板轮询监控（0.5s 间隔）
    │   ├── HotKeyManager.swift         # 全局 ⌘⇧V 快捷键（Carbon API）
    │   └── StorageManager.swift        # UserDefaults 持久化
    ├── ViewModels/
    │   └── ClipboardViewModel.swift    # 业务逻辑 & 模拟粘贴
    └── Views/
        ├── ClipboardPanelView.swift    # 浮动历史面板
        ├── ClipboardItemRow.swift      # 列表行组件
        └── SettingsView.swift          # 设置界面
```

## 开源协议

MIT

# ClipboardManager

[中文文档](README_CN.md)

A lightweight macOS menu bar app that keeps your clipboard history, inspired by Windows' built-in clipboard history (Win+V).

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Clipboard History** — Automatically saves your last 50 copied text items
- **Global Hotkey** — Press `⌘⇧V` to instantly bring up the clipboard panel
- **Non-activating Floating Panel** — Panel does not steal focus from the active input field
- **Keyboard Navigation** — Use `↑`/`↓` arrow keys to select items and `Enter` to paste, without losing focus on the target app
- **Position Near Input** — Panel appears next to the focused input element, like Windows clipboard
- **Continuous Paste** — Panel stays open after pasting, allowing multiple items to be pasted in sequence
- **Menu Bar App** — Lives quietly in your menu bar, no Dock icon
- **Quick Paste** — Click any item to paste it into the active app
- **Search** — Filter through your clipboard history
- **Deduplication** — Duplicate entries are moved to the top after the panel is closed
- **Persistent Storage** — History survives app restarts
- **Native macOS** — Built with Swift & SwiftUI, lightweight and fast

## Screenshot

```
┌─────────────────────────────┐
│  Clipboard History   Clear All │
├─────────────────────────────┤
│  🔍 Search...                  │
├─────────────────────────────┤
│  Hello world                   │
│  2 minutes ago              ✕  │
├─────────────────────────────┤
│  https://github.com            │
│  5 minutes ago              ✕  │
├─────────────────────────────┤
│  func example() { ... }       │
│  1 hour ago                 ✕  │
└─────────────────────────────┘
```

## Requirements

- macOS 13.0 (Ventura) or later
- Accessibility permission (for global hotkey and auto-paste)

## Installation

### Build from Source

```bash
git clone https://github.com/LonelySnow1/ClipboardManager.git
cd ClipboardManager
swift build -c release
```

The built binary will be at `.build/release/ClipboardManager`.

### Run

```bash
swift run
```

Or copy the binary to `/Applications` or `/usr/local/bin`.

## Setup

On first launch, macOS will ask you to grant **Accessibility** permission:

1. Open **System Settings > Privacy & Security > Accessibility**
2. Click the `+` button and add `ClipboardManager`
3. Restart the app

This permission is required for:
- Global hotkey (`⌘⇧V`) to work system-wide
- Auto-paste functionality (simulates `⌘V` after selecting an item)
- Reading focused input element position via Accessibility API

## Usage

| Action | How |
|--------|-----|
| Open clipboard panel | Click menu bar icon or press `⌘⇧V` |
| Select item | Use `↑`/`↓` arrow keys |
| Paste selected item | Press `Enter` |
| Paste an item by click | Click on it in the panel |
| Paste multiple items | Keep selecting and pressing Enter — panel stays open |
| Close panel | Press `Esc`, click outside the panel, or press `⌘⇧V` again |
| Delete an item | Hover and click the `✕` button |
| Search history | Type in the search field |
| Clear all history | Click "Clear All" |

## Project Structure

```
├── Package.swift
├── README.md
├── README_CN.md
└── ClipboardManager/
    ├── ClipboardManagerApp.swift       # App entry point, NSPanel & positioning
    ├── Models/
    │   └── ClipboardItem.swift         # Data model
    ├── Services/
    │   ├── ClipboardMonitor.swift      # Pasteboard polling (0.5s interval)
    │   ├── HotKeyManager.swift         # Global ⌘⇧V hotkey (CGEvent tap)
    │   ├── PanelKeyHandler.swift       # Keyboard navigation (CGEvent tap for ↑↓/Enter/Esc)
    │   └── StorageManager.swift        # UserDefaults persistence
    ├── ViewModels/
    │   └── ClipboardViewModel.swift    # Business logic & paste simulation
    └── Views/
        ├── ClipboardPanelView.swift    # Main floating panel
        ├── ClipboardItemRow.swift      # List row component
        └── SettingsView.swift          # Preferences window
```

## License

MIT

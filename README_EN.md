# KeyStats - macOS Keyboard & Mouse Statistics Menu Bar App

English | [简体中文](./README.md)

<img width="128" height="128" alt="ICON-iOS-Default-256x256@2x" src="https://github.com/user-attachments/assets/842780ed-c7a1-4c1b-a901-1f1d8babe51a" />


KeyStats is a lightweight macOS native menu bar application that tracks daily keyboard keystrokes, mouse clicks, mouse movement distance, and scroll distance.

<img width="300" height="581" alt="image" src="https://github.com/user-attachments/assets/c5146f66-0aa3-49ce-9184-2c75301bf398" />

## Installation & Usage

### macOS

#### Option 1: Install via Homebrew

```bash
# Tap the repository
brew tap debugtheworldbot/keystats

# Install the app
brew install keystats
```

Update the app:
```bash
brew upgrade keystats
```

#### Option 2: [Download from GitHub Releases](https://github.com/debugtheworldbot/keyStats/releases)

### Windows

[Download from GitHub Releases](https://github.com/debugtheworldbot/keyStats/releases) the Windows installer

> **About .NET 8 Desktop Runtime:** If .NET 8 Desktop Runtime is not installed on your computer, a setup wizard will automatically appear when you first open the app - just follow the prompts. You can also [download and install it manually](https://dotnet.microsoft.com/download/dotnet/8.0) in advance.

## Features

- **Keyboard Keystroke Statistics**: Real-time tracking of daily key presses
- **Mouse Click Statistics**: Separate tracking of left and right clicks
- **Mouse Movement Distance**: Track total distance of mouse movement
- **Scroll Distance Statistics**: Record cumulative page scroll distance
- **Menu Bar Display**: Core data displayed directly in macOS menu bar
- **Detailed Panel**: Click menu bar icon to view complete statistics
- **Daily Auto-Reset**: Statistics automatically reset at midnight
- **Data Persistence**: Data persists after application restart

## System Requirements

### macOS
- macOS 13.0 (Ventura) or higher

### Windows
- Windows 10 or higher
- **[.NET 8 Desktop Runtime](https://dotnet.microsoft.com/download/dotnet/8.0) must be installed first**

> **Why is .NET 8 Desktop Runtime required?**
> The Windows version is built with WPF (Windows Presentation Foundation), Microsoft's official desktop application framework, which requires the .NET runtime environment to run. If .NET 8 Desktop Runtime is not installed on your computer, the application will not launch.


## First Run Permission Setup

### macOS

KeyStats requires **Accessibility permissions** to monitor keyboard and mouse events. On first run:

1. The app will prompt a permission request dialog
2. Click "Open System Settings"
3. Find KeyStats in "Privacy & Security" > "Accessibility"
4. Enable the permission toggle for KeyStats
5. Once authorized, the app will automatically start tracking

> **Note**: Without granting permissions, the app will not be able to track any data.
>
> **Reinstall/upgrade tip**: Because the app is not signed, macOS will not automatically update Accessibility authorization after each reinstall. Remove the existing KeyStats entry in "Privacy & Security" > "Accessibility", then return to the app and click the "Get Permission" button to request access again.

### Windows

The Windows version **requires no additional permission setup**. The app will automatically start tracking once launched.

> **Note**: On first launch, Windows may show a security warning. Click "Run anyway" to proceed.

## Usage Instructions

### Menu Bar Display

Once the app is running, the menu bar will show:

```
123
45
```

- The upper number represents total keyboard presses today
- The lower number represents total mouse clicks today (including left and right buttons)

Large numbers are automatically formatted:
- 1,000+ displayed as `1.0K`
- 1,000,000+ displayed as `1.0M`

### Detailed Panel

Clicking the menu bar icon opens the detailed statistics panel, showing:

| Statistic | Description |
|-----------|-------------|
| Keyboard Strokes | Total key presses today |
| Left Clicks | Mouse left button clicks |
| Right Clicks | Mouse right button clicks |
| Mouse Movement | Total distance of mouse movement |
| Scroll Distance | Cumulative page scroll distance |

### Action Buttons

- **Reset Statistics**: Manually clear all statistics for today
- **Quit Application**: Close KeyStats

## Project Structure

### macOS

```
KeyStats/
├── KeyStats.xcodeproj/     # Xcode project files
├── KeyStats/
│   ├── AppDelegate.swift           # Application entry point, permission management
│   ├── InputMonitor.swift          # Input event monitor
│   ├── StatsManager.swift          # Statistics data manager
│   ├── MenuBarController.swift     # Menu bar controller
│   ├── StatsPopoverViewController.swift  # Detailed panel view
│   ├── Info.plist                  # Application configuration
│   ├── KeyStats.entitlements       # Permission configuration
│   ├── Main.storyboard             # Main interface
│   └── Assets.xcassets/            # Resource files
└── README.md
```

### Windows

```
KeyStats.Windows/
├── KeyStats.sln                    # Visual Studio solution file
├── KeyStats/
│   ├── App.xaml                    # Application entry definition
│   ├── App.xaml.cs                 # Application entry logic
│   ├── Services/
│   │   ├── InputMonitorService.cs  # Input event monitor service
│   │   ├── StatsManager.cs         # Statistics data manager
│   │   ├── NotificationService.cs  # Notification service
│   │   └── StartupManager.cs       # Startup management
│   ├── ViewModels/
│   │   ├── TrayIconViewModel.cs    # Tray icon view model
│   │   └── StatsPopupViewModel.cs  # Stats popup view model
│   ├── Views/
│   │   └── StatsPopupWindow.xaml   # Stats popup window
│   ├── Models/                     # Data models
│   ├── Helpers/                    # Utility classes
│   └── Resources/                  # Resource files
└── build.ps1                       # Build script
```

## Technical Implementation

### macOS

- **Language**: Swift 5.0
- **Frameworks**: AppKit, CoreGraphics
- **Event Monitoring**: Global event listener using `CGEvent.tapCreate`
- **Data Storage**: Local persistence using `UserDefaults`
- **UI Mode**: Pure menu bar application (LSUIElement = true)

### Windows

- **Language**: C# 12
- **Framework**: WPF (.NET 8)
- **Architecture**: MVVM (Model-View-ViewModel)
- **Event Monitoring**: Windows low-level keyboard/mouse hooks (SetWindowsHookEx)
- **Data Storage**: Local persistence using JSON files
- **UI Mode**: System tray application

## Privacy Statement

KeyStats only tracks the **count** of keystrokes and clicks, and **does NOT record**:
- Which specific keys were pressed
- Text content that was typed
- Specific click locations or applications

All data is stored locally only and is never uploaded to any server.

## License

MIT License

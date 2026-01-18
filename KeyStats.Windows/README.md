# KeyStats for Windows

A keyboard and mouse statistics tracker for Windows, ported from the macOS version.

## Features

- **Input Monitoring**: Tracks key presses, mouse clicks, mouse movement distance, and scroll distance
- **System Tray Integration**: Runs in the system tray with a tooltip showing current stats
- **Statistics Popup**: Click the tray icon to see detailed statistics
- **Key Breakdown**: Shows the top 15 most pressed keys
- **History Charts**: View historical data in line or bar chart format (week/month)
- **Dynamic Icon Color**: Icon color changes based on typing speed (APM)
- **Notifications**: Get notified when you reach milestones
- **Startup with Windows**: Option to launch automatically at system startup

## Requirements

- Windows 10 or Windows 11
- .NET 8.0 Runtime

## Building

### Prerequisites

- Visual Studio 2022 (17.8 or later) with .NET desktop development workload
- Or .NET 8.0 SDK

### Build with Visual Studio

1. Open `KeyStats.sln` in Visual Studio
2. Build the solution (Ctrl+Shift+B)
3. Run with F5 or from the bin folder

### Build with Command Line

```bash
cd KeyStats.Windows
dotnet build
dotnet run --project KeyStats
```

### Publish for Distribution

#### 使用打包脚本（推荐）

```powershell
# PowerShell - 自包含版本（推荐，无需安装 .NET）
.\build.ps1

# PowerShell - 框架依赖版本（需要 .NET 8.0 Runtime，文件更小）
.\build.ps1 -PublishType FrameworkDependent

# 批处理文件（Windows）
build.bat Release SelfContained
```

**参数说明：**
- `Configuration`: `Release` 或 `Debug`（默认：Release）
- `PublishType`: `SelfContained`（自包含，无需 .NET 运行时）或 `FrameworkDependent`（需要 .NET 运行时，默认：SelfContained）
- `Runtime`: `win-x64`、`win-x86` 或 `win-arm64`（默认：win-x64）

**输出：**
- 发布文件：`publish/` 目录
- 打包文件：`dist/KeyStats-Windows-<版本>-<运行时>-<类型>.zip`

#### 两种打包方式对比

| 特性 | SelfContained（自包含） | FrameworkDependent（框架依赖） |
|------|------------------------|------------------------------|
| **文件大小** | ~100-120 MB（优化后） | ~5-10 MB |
| **需要安装 .NET** | ❌ 不需要 | ✅ 需要 .NET 8.0 Desktop Runtime |
| **安装难度** | 开箱即用 | 非常简单（见下方说明） |
| **启动速度** | 稍慢（首次解压） | 更快 |
| **适用场景** | 分发给不熟悉技术的用户 | 分发给开发者或技术用户 |
| **推荐度** | ⭐⭐⭐⭐⭐ 推荐 | ⭐⭐⭐ 可选 |

**安装 .NET 8.0 Runtime 说明：**

安装非常简单，只需 1-2 分钟：

1. **自动安装（最简单）**：
   - 首次运行 FrameworkDependent 版本时，Windows 可能会自动提示下载安装
   - 点击提示即可完成安装
   - **注意**：如果 Windows 没有自动提示，会显示系统错误对话框（英文），提示找不到运行时

2. **手动安装（推荐）**：
   - 访问：https://dotnet.microsoft.com/download/dotnet/8.0
   - 下载 "Desktop Runtime"（约 50MB）
   - 双击安装即可

3. **包管理器安装**：
   ```powershell
   # Chocolatey
   choco install dotnet-desktopruntime-8.0
   
   # winget
   winget install Microsoft.DotNet.DesktopRuntime.8
   ```

**如果未安装 .NET Runtime 会发生什么？**

如果用户在没有安装 .NET 8.0 Desktop Runtime 的情况下运行 FrameworkDependent 版本：

1. **Windows 系统错误对话框**：
   - 会显示一个系统错误对话框（英文）
   - 标题类似："This application requires one of the following versions of the .NET Framework"
   - 或者："To run this application, you must install .NET Desktop Runtime 8.0"

2. **应用无法启动**：
   - 应用不会启动，不会显示任何界面
   - 用户需要先安装 .NET Runtime 才能使用

3. **解决方案**：
   - 按照上面的说明安装 .NET 8.0 Desktop Runtime
   - 或者使用 SelfContained 版本（无需安装，开箱即用）

**使用启动器脚本（可选）**：

FrameworkDependent 版本包含两个启动器脚本，可以在启动前检查运行时并显示友好的中文提示：

- `CheckRuntime.bat` - 批处理启动器（推荐）
- `CheckRuntime.ps1` - PowerShell 启动器（功能更丰富）

使用方法：双击 `CheckRuntime.bat` 而不是直接运行 `KeyStats.exe`。如果运行时未安装，会显示中文提示并可以自动打开下载页面。

**建议：**
- 如果分发给普通用户 → 使用 **SelfContained**（无需安装，开箱即用）
- 如果分发给开发者或技术用户 → 可以使用 **FrameworkDependent**（文件更小）

#### 手动发布

```bash
# Self-contained single-file executable
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true

# Framework-dependent (smaller size, requires .NET runtime)
dotnet publish -c Release -r win-x64 --self-contained false
```

## Project Structure

```
KeyStats.Windows/
├── KeyStats.sln                          # Solution file
├── KeyStats/
│   ├── App.xaml(.cs)                     # Application entry point
│   ├── Services/
│   │   ├── InputMonitorService.cs        # Keyboard/mouse hooks
│   │   ├── StatsManager.cs               # Statistics management
│   │   ├── NotificationService.cs        # Toast notifications
│   │   └── StartupManager.cs             # Windows startup
│   ├── ViewModels/
│   │   ├── ViewModelBase.cs              # MVVM base class
│   │   ├── TrayIconViewModel.cs          # Tray icon logic
│   │   ├── StatsPopupViewModel.cs        # Stats popup logic
│   │   └── SettingsViewModel.cs          # Settings logic
│   ├── Views/
│   │   ├── StatsPopupWindow.xaml         # Stats popup UI
│   │   ├── SettingsWindow.xaml           # Settings UI
│   │   └── Controls/
│   │       ├── StatItemControl.xaml      # Single stat display
│   │       ├── KeyBreakdownControl.xaml  # Key breakdown grid
│   │       └── StatsChartControl.xaml    # History chart
│   ├── Models/
│   │   ├── DailyStats.cs                 # Daily statistics model
│   │   └── AppSettings.cs                # User settings model
│   └── Helpers/
│       ├── NativeInterop.cs              # Windows API P/Invoke
│       ├── KeyNameMapper.cs              # Virtual key to name mapping
│       ├── IconGenerator.cs              # Dynamic icon generation
│       └── Converters.cs                 # XAML value converters
```

## Data Storage

Data is stored in `%LOCALAPPDATA%\KeyStats\`:
- `daily_stats.json` - Current day's statistics
- `history.json` - Historical data (30 days)
- `settings.json` - User preferences

## Technical Notes

### Input Monitoring

Uses low-level Windows hooks (`SetWindowsHookEx`) with:
- `WH_KEYBOARD_LL` for keyboard events
- `WH_MOUSE_LL` for mouse events

Mouse movement is sampled at 30 FPS to avoid excessive CPU usage.
Jumps greater than 500 pixels are filtered out (e.g., when mouse teleports).

### Dynamic Icon Color (APM)

The tray icon color changes based on typing speed:
- No color: < 80 APM
- Light green to green: 80-160 APM
- Yellow to red: 160-240+ APM

APM is calculated using a 3-second sliding window with 0.5-second buckets.

## Differences from macOS Version

| Aspect | macOS | Windows |
|--------|-------|---------|
| Permissions | Accessibility permission required | No special permissions |
| Tray display | Shows text + icon | Icon only (text in tooltip) |
| Popup behavior | NSPopover anchored to menu bar | Borderless window near tray |
| Hook mechanism | CGEvent tap | SetWindowsHookEx |
| Startup | SMAppService | Registry Run key |

## License

Same license as the macOS KeyStats application.

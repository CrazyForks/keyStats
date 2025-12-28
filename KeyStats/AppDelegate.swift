import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var menuBarController: MenuBarController?
    private var permissionCheckTimer: Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 初始化菜单栏控制器
        menuBarController = MenuBarController()
        applyAppIcon()
        
        // 检查并请求辅助功能权限
        checkAndRequestPermission()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // 停止输入监听
        InputMonitor.shared.stopMonitoring()
        permissionCheckTimer?.invalidate()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - 权限检查
    
    private func checkAndRequestPermission() {
        if InputMonitor.shared.hasAccessibilityPermission() {
            // 已有权限，直接开始监听
            InputMonitor.shared.startMonitoring()
        } else {
            // 请求权限并显示提示
            showPermissionAlert()
            
            // 定期检查权限状态
            permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
                if InputMonitor.shared.hasAccessibilityPermission() {
                    timer.invalidate()
                    self?.permissionCheckTimer = nil
                    InputMonitor.shared.startMonitoring()
                }
            }
        }
    }
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = """
        KeyStats 需要辅助功能权限来监听键盘和鼠标事件。
        
        请按照以下步骤授权：
        1. 点击"打开系统设置"
        2. 在"隐私与安全性"中找到"辅助功能"
        3. 启用 KeyStats 的权限
        
        授权后，应用将自动开始统计。
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")
        
        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
        
        // 触发系统权限请求弹窗
        _ = InputMonitor.shared.checkAccessibilityPermission()
    }
    
    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    private func applyAppIcon() {
        let symbolName = "button.horizontal.top.press.fill"
        let config = NSImage.SymbolConfiguration(pointSize: 256, weight: .regular)
        guard let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else {
            return
        }
        image.isTemplate = false
        NSApp.applicationIconImage = image
    }
}

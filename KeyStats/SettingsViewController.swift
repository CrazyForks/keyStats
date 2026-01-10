import Cocoa

class SettingsViewController: NSViewController {

    private var appIconView: NSImageView!
    private var showKeyPressesButton: NSButton!
    private var showMouseClicksButton: NSButton!
    private var launchAtLoginButton: NSButton!
    private var resetButton: NSButton!

    // MARK: - Lifecycle

    override func loadView() {
        let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 240))
        mainView.wantsLayer = true
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateState()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        updateState()
    }

    // MARK: - UI

    private func setupUI() {
        appIconView = NSImageView()
        appIconView.image = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage
        appIconView.imageScaling = .scaleProportionallyUpOrDown
        appIconView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(appIconView)

        showKeyPressesButton = NSButton(checkboxWithTitle: NSLocalizedString("setting.showKeyPresses", comment: ""),
                                        target: self,
                                        action: #selector(toggleShowKeyPresses))

        showMouseClicksButton = NSButton(checkboxWithTitle: NSLocalizedString("setting.showMouseClicks", comment: ""),
                                         target: self,
                                         action: #selector(toggleShowMouseClicks))

        launchAtLoginButton = NSButton(checkboxWithTitle: NSLocalizedString("button.launchAtLogin", comment: ""),
                                       target: self,
                                       action: #selector(toggleLaunchAtLogin))

        let optionsStack = NSStackView(views: [showKeyPressesButton, showMouseClicksButton, launchAtLoginButton])
        optionsStack.orientation = .vertical
        optionsStack.alignment = .leading
        optionsStack.spacing = 8
        optionsStack.translatesAutoresizingMaskIntoConstraints = false

        resetButton = NSButton(title: NSLocalizedString("button.reset", comment: ""), target: self, action: #selector(resetStats))
        resetButton.bezelStyle = .rounded
        resetButton.controlSize = .regular

        let contentStack = NSStackView(views: [optionsStack, resetButton])
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)

        NSLayoutConstraint.activate([
            appIconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            appIconView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            appIconView.widthAnchor.constraint(equalToConstant: 48),
            appIconView.heightAnchor.constraint(equalToConstant: 48),

            contentStack.topAnchor.constraint(equalTo: appIconView.bottomAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - State

    private func updateState() {
        showKeyPressesButton.state = StatsManager.shared.showKeyPressesInMenuBar ? .on : .off
        showMouseClicksButton.state = StatsManager.shared.showMouseClicksInMenuBar ? .on : .off
        launchAtLoginButton.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
    }

    // MARK: - Actions

    @objc private func toggleShowKeyPresses() {
        StatsManager.shared.showKeyPressesInMenuBar = (showKeyPressesButton.state == .on)
    }

    @objc private func toggleShowMouseClicks() {
        StatsManager.shared.showMouseClicksInMenuBar = (showMouseClicksButton.state == .on)
    }

    @objc private func toggleLaunchAtLogin() {
        let shouldEnable = launchAtLoginButton.state == .on
        do {
            try LaunchAtLoginManager.shared.setEnabled(shouldEnable)
            updateState()
        } catch {
            updateState()
            showLaunchAtLoginError()
        }
    }

    @objc private func resetStats() {
        let alert = NSAlert()
        let appIcon = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage
        alert.icon = appIcon
        alert.messageText = NSLocalizedString("stats.reset.title", comment: "")
        alert.informativeText = NSLocalizedString("stats.reset.message", comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("stats.reset.confirm", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("stats.reset.cancel", comment: ""))

        if alert.runModal() == .alertFirstButtonReturn {
            StatsManager.shared.resetStats()
        }
    }

    private func showLaunchAtLoginError() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("launchAtLogin.error.title", comment: "")
        alert.informativeText = NSLocalizedString("launchAtLogin.error.message", comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("button.ok", comment: ""))
        alert.runModal()
    }
}

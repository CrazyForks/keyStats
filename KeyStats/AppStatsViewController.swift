import Cocoa

final class AppStatsViewController: NSViewController {
    private var scrollView: NSScrollView!
    private var documentView: NSView!
    private var containerStack: NSStackView!
    private var titleLabel: NSTextField!
    private var subtitleLabel: NSTextField!
    private var rangeControl: NSSegmentedControl!
    private var summaryLabel: NSTextField!
    private var listHeaderView: AppStatsHeaderRowView!
    private var listStack: NSStackView!
    private var emptyStateLabel: NSTextField!
    private var statsUpdateToken: UUID?
    private var pendingRefresh = false
    private var sortMetric: SortMetric = .keys
    private var columnWidths = AppStatsColumnWidths(
        app: AppStatsLayout.appColumnWidth,
        keys: AppStatsLayout.keysColumnWidth,
        clicks: AppStatsLayout.clicksColumnWidth,
        scroll: AppStatsLayout.scrollColumnWidth
    )
    private let columnWidthsDefaultsKey = "appStats.columnWidths"

    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    // MARK: - Lifecycle

    override func loadView() {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 640))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadPersistedColumnWidths()
        setupUI()
        refreshData()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        refreshData()
        startLiveUpdates()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        stopLiveUpdates()
    }

    deinit {
        stopLiveUpdates()
    }

    // MARK: - UI

    private func setupUI() {
        scrollView = NSScrollView(frame: view.bounds)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        view.addSubview(scrollView)

        let headerContainer = NSView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerContainer)

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        documentView = FlippedView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView

        containerStack = NSStackView()
        containerStack.orientation = .vertical
        containerStack.alignment = .leading
        containerStack.spacing = 18
        containerStack.edgeInsets = NSEdgeInsets(top: 12, left: 28, bottom: 28, right: 28)
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(containerStack)

        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: documentView.topAnchor),
            containerStack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            containerStack.bottomAnchor.constraint(equalTo: documentView.bottomAnchor),
            containerStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        rangeControl = NSSegmentedControl(labels: [
            NSLocalizedString("appStats.range.today", comment: ""),
            NSLocalizedString("appStats.range.week", comment: ""),
            NSLocalizedString("appStats.range.month", comment: ""),
            NSLocalizedString("appStats.range.all", comment: "")
        ], trackingMode: .selectOne, target: self, action: #selector(controlsChanged))
        rangeControl.selectedSegment = 0

        let controlsStack = NSStackView(views: [rangeControl])
        controlsStack.orientation = .vertical
        controlsStack.alignment = .leading
        controlsStack.spacing = 8

        let headerStack = NSStackView()
        headerStack.orientation = .vertical
        headerStack.alignment = .leading
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(headerStack)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 28),
            headerStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -28),
            headerStack.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -12)
        ])

        titleLabel = NSTextField(labelWithString: NSLocalizedString("appStats.title", comment: ""))
        titleLabel.font = NSFont.systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .labelColor

        subtitleLabel = NSTextField(wrappingLabelWithString: NSLocalizedString("appStats.subtitle", comment: ""))
        subtitleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        subtitleLabel.textColor = .secondaryLabelColor

        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(subtitleLabel)
        headerStack.addArrangedSubview(controlsStack)

        emptyStateLabel = NSTextField(labelWithString: "")
        emptyStateLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        emptyStateLabel.textColor = .secondaryLabelColor
        emptyStateLabel.isHidden = true

        summaryLabel = NSTextField(labelWithString: "")
        summaryLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        summaryLabel.textColor = .secondaryLabelColor

        headerStack.addArrangedSubview(emptyStateLabel)
        headerStack.addArrangedSubview(summaryLabel)

        listHeaderView = AppStatsHeaderRowView()
        listHeaderView.sortMetricHandler = { [weak self] metric in
            self?.updateSortMetric(metric)
        }
        listHeaderView.columnResizeHandler = { [weak self] divider, delta in
            self?.resizeColumn(divider: divider, delta: delta)
        }
        listHeaderView.updateSortIndicator(selectedMetric: sortMetric)
        listHeaderView.applyColumnWidths(columnWidths)
        containerStack.addArrangedSubview(listHeaderView)
        listHeaderView.widthAnchor.constraint(equalTo: containerStack.widthAnchor, constant: -56).isActive = true
        containerStack.setCustomSpacing(0, after: listHeaderView)

        listStack = NSStackView()
        listStack.orientation = .vertical
        listStack.alignment = .leading
        listStack.spacing = 0
        containerStack.addArrangedSubview(listStack)
        listStack.widthAnchor.constraint(equalTo: containerStack.widthAnchor, constant: -56).isActive = true

        containerStack.addArrangedSubview(NSView())
    }

    // MARK: - Data

    func refreshData() {
        pendingRefresh = false
        let statsManager = StatsManager.shared
        if !statsManager.appStatsEnabled {
            updateEmptyState(text: NSLocalizedString("appStats.disabled", comment: ""))
            return
        }

        let range = selectedRange()
        var items = statsManager.appStatsSummary(range: range)
        items = items.filter { $0.hasActivity }
        items.sort { lhs, rhs in
            let lhsValue = sortValue(for: lhs)
            let rhsValue = sortValue(for: rhs)
            if lhsValue != rhsValue {
                return lhsValue > rhsValue
            }
            return displayName(for: lhs).localizedCaseInsensitiveCompare(displayName(for: rhs)) == .orderedAscending
        }

        updateSummary(with: items)
        updateList(with: items)
    }

    private func updateSummary(with items: [AppStats]) {
        summaryLabel.isHidden = false
        let totalKeys = items.reduce(0) { $0 + $1.keyPresses }
        let totalClicks = items.reduce(0) { $0 + $1.totalClicks }
        let totalScroll = items.reduce(0) { $0 + $1.scrollDistance }
        let formattedKeys = formatNumber(totalKeys)
        let formattedClicks = formatNumber(totalClicks)
        let formattedScroll = formatScrollDistance(totalScroll)
        summaryLabel.stringValue = String(
            format: NSLocalizedString("appStats.summary", comment: ""),
            formattedKeys,
            formattedClicks,
            formattedScroll
        )
    }

    private func updateList(with items: [AppStats]) {
        listStack.arrangedSubviews.forEach {
            listStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard !items.isEmpty else {
            updateEmptyState(text: NSLocalizedString("appStats.empty", comment: ""))
            return
        }

        listHeaderView.isHidden = false
        emptyStateLabel.isHidden = true

        for item in items {
            let row = AppStatsRowView()
            row.columnResizeHandler = { [weak self] divider, delta in
                self?.resizeColumn(divider: divider, delta: delta)
            }
            row.applyColumnWidths(columnWidths)
            row.update(
                name: displayName(for: item),
                keyPresses: formatNumber(item.keyPresses),
                clicks: formatNumber(item.totalClicks),
                scroll: formatScrollDistance(item.scrollDistance)
            )
            listStack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: listStack.widthAnchor).isActive = true
        }
    }

    private func updateEmptyState(text: String) {
        listHeaderView.isHidden = true
        listStack.arrangedSubviews.forEach {
            listStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        emptyStateLabel.stringValue = text
        emptyStateLabel.isHidden = false
        summaryLabel.stringValue = ""
        summaryLabel.isHidden = true
    }

    private func displayName(for stats: AppStats) -> String {
        if !stats.displayName.isEmpty {
            return stats.displayName
        }
        return NSLocalizedString("appStats.unknownApp", comment: "")
    }

    private func sortValue(for stats: AppStats) -> Double {
        switch sortMetric {
        case .keys:
            return Double(stats.keyPresses)
        case .clicks:
            return Double(stats.totalClicks)
        case .scroll:
            return stats.scrollDistance
        }
    }

    private func formatNumber(_ number: Int) -> String {
        return numberFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private func formatScrollDistance(_ distance: Double) -> String {
        if distance >= 10000 {
            return String(format: "%.1f k", distance / 1000)
        }
        return String(format: "%.0f px", distance)
    }

    // MARK: - Column Layout

    private func resizeColumn(divider: AppStatsColumnDivider, delta: CGFloat) {
        guard delta != 0 else { return }
        switch divider {
        case .appKeys:
            let clamped = clampedDelta(
                delta,
                leftWidth: columnWidths.app,
                leftMin: AppStatsLayout.minAppColumnWidth,
                rightWidth: columnWidths.keys,
                rightMin: AppStatsLayout.minKeysColumnWidth
            )
            guard clamped != 0 else { return }
            columnWidths.app += clamped
            columnWidths.keys -= clamped
        case .keysClicks:
            let clamped = clampedDelta(
                delta,
                leftWidth: columnWidths.keys,
                leftMin: AppStatsLayout.minKeysColumnWidth,
                rightWidth: columnWidths.clicks,
                rightMin: AppStatsLayout.minClicksColumnWidth
            )
            guard clamped != 0 else { return }
            columnWidths.keys += clamped
            columnWidths.clicks -= clamped
        case .clicksScroll:
            let clamped = clampedDelta(
                delta,
                leftWidth: columnWidths.clicks,
                leftMin: AppStatsLayout.minClicksColumnWidth,
                rightWidth: columnWidths.scroll,
                rightMin: AppStatsLayout.minScrollColumnWidth
            )
            guard clamped != 0 else { return }
            columnWidths.clicks += clamped
            columnWidths.scroll -= clamped
        }
        applyColumnWidths()
        saveColumnWidths()
    }

    private func clampedDelta(
        _ delta: CGFloat,
        leftWidth: CGFloat,
        leftMin: CGFloat,
        rightWidth: CGFloat,
        rightMin: CGFloat
    ) -> CGFloat {
        let maxIncrease = rightWidth - rightMin
        let maxDecrease = leftWidth - leftMin
        return min(max(delta, -maxDecrease), maxIncrease)
    }

    private func applyColumnWidths() {
        listHeaderView.applyColumnWidths(columnWidths)
        for case let row as AppStatsRowView in listStack.arrangedSubviews {
            row.applyColumnWidths(columnWidths)
        }
        view.layoutSubtreeIfNeeded()
    }

    private func loadPersistedColumnWidths() {
        guard let saved = UserDefaults.standard.dictionary(forKey: columnWidthsDefaultsKey) as? [String: Double] else {
            return
        }
        columnWidths = AppStatsColumnWidths(
            app: validatedWidth(saved["app"], min: AppStatsLayout.minAppColumnWidth, fallback: AppStatsLayout.appColumnWidth),
            keys: validatedWidth(saved["keys"], min: AppStatsLayout.minKeysColumnWidth, fallback: AppStatsLayout.keysColumnWidth),
            clicks: validatedWidth(saved["clicks"], min: AppStatsLayout.minClicksColumnWidth, fallback: AppStatsLayout.clicksColumnWidth),
            scroll: validatedWidth(saved["scroll"], min: AppStatsLayout.minScrollColumnWidth, fallback: AppStatsLayout.scrollColumnWidth)
        )
    }

    private func saveColumnWidths() {
        let payload: [String: Double] = [
            "app": Double(columnWidths.app),
            "keys": Double(columnWidths.keys),
            "clicks": Double(columnWidths.clicks),
            "scroll": Double(columnWidths.scroll)
        ]
        UserDefaults.standard.set(payload, forKey: columnWidthsDefaultsKey)
    }

    private func validatedWidth(_ value: Double?, min: CGFloat, fallback: CGFloat) -> CGFloat {
        guard let value = value else { return fallback }
        let width = CGFloat(value)
        guard width.isFinite else { return fallback }
        return max(min, width)
    }

    // MARK: - Updates

    private func startLiveUpdates() {
        statsUpdateToken = StatsManager.shared.addStatsUpdateHandler { [weak self] in
            self?.scheduleRefresh()
        }
    }

    private func stopLiveUpdates() {
        if let token = statsUpdateToken {
            StatsManager.shared.removeStatsUpdateHandler(token)
        }
        statsUpdateToken = nil
        pendingRefresh = false
    }

    private func scheduleRefresh() {
        guard !pendingRefresh else { return }
        pendingRefresh = true
        DispatchQueue.main.async { [weak self] in
            self?.refreshData()
        }
    }

    // MARK: - Controls

    @objc private func controlsChanged() {
        refreshData()
    }

    private func updateSortMetric(_ metric: SortMetric) {
        sortMetric = metric
        listHeaderView.updateSortIndicator(selectedMetric: metric)
        refreshData()
    }

    private func selectedRange() -> StatsManager.AppStatsRange {
        switch rangeControl.selectedSegment {
        case 0:
            return .today
        case 1:
            return .week
        case 2:
            return .month
        default:
            return .all
        }
    }
}

private enum SortMetric {
    case keys
    case clicks
    case scroll
}

private struct AppStatsColumnWidths {
    var app: CGFloat
    var keys: CGFloat
    var clicks: CGFloat
    var scroll: CGFloat
}

private enum AppStatsColumnDivider {
    case appKeys
    case keysClicks
    case clicksScroll
}

private final class FlippedView: NSView {
    override var isFlipped: Bool {
        return true
    }
}

private enum AppStatsLayout {
    static let appColumnWidth: CGFloat = 220
    static let keysColumnWidth: CGFloat = 80
    static let clicksColumnWidth: CGFloat = 80
    static let scrollColumnWidth: CGFloat = 90
    static let columnSpacing: CGFloat = 12
    static let rowHeight: CGFloat = 32
    static let headerHeight: CGFloat = 20
    static let nameColumnHeight: CGFloat = 22
    static let minAppColumnWidth: CGFloat = 140
    static let minKeysColumnWidth: CGFloat = 60
    static let minClicksColumnWidth: CGFloat = 60
    static let minScrollColumnWidth: CGFloat = 70
    static let dividerThickness: CGFloat = 1
    static let dividerHitWidth: CGFloat = 6
    static let dividerVerticalInset: CGFloat = 0
}

private final class SortableHeaderLabel: NSTextField {
    let metric: SortMetric
    let baseText: String
    var onClick: ((SortMetric) -> Void)?

    init(text: String, metric: SortMetric) {
        self.baseText = text
        self.metric = metric
        super.init(frame: .zero)
        isEditable = false
        isBordered = false
        drawsBackground = false
        isSelectable = false
        stringValue = text
        focusRingType = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        onClick?(metric)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    func updateIndicator(_ indicator: String?) {
        if let indicator = indicator, !indicator.isEmpty {
            stringValue = "\(baseText) \(indicator)"
        } else {
            stringValue = baseText
        }
    }
}

private final class AppStatsHeaderRowView: NSView {
    private let sortIndicator = NSLocalizedString("appStats.sortIndicator", comment: "")
    private var nameLabel: NSTextField!
    private var keysLabel: SortableHeaderLabel!
    private var clicksLabel: SortableHeaderLabel!
    private var scrollLabel: SortableHeaderLabel!
    private var nameWidthConstraint: NSLayoutConstraint!
    private var keysWidthConstraint: NSLayoutConstraint!
    private var clicksWidthConstraint: NSLayoutConstraint!
    private var scrollWidthConstraint: NSLayoutConstraint!

    var sortMetricHandler: ((SortMetric) -> Void)?
    var columnResizeHandler: ((AppStatsColumnDivider, CGFloat) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: AppStatsLayout.headerHeight).isActive = true

        nameLabel = makeHeaderLabel(text: NSLocalizedString("appStats.column.app", comment: ""), isNameColumn: true)
        keysLabel = makeSortableHeaderLabel(text: NSLocalizedString("appStats.column.keys", comment: ""), metric: .keys)
        clicksLabel = makeSortableHeaderLabel(text: NSLocalizedString("appStats.column.clicks", comment: ""), metric: .clicks)
        scrollLabel = makeSortableHeaderLabel(text: NSLocalizedString("appStats.column.scroll", comment: ""), metric: .scroll)

        let stack = NSStackView(views: [nameLabel, keysLabel, clicksLabel, scrollLabel])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = AppStatsLayout.columnSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        nameWidthConstraint = nameLabel.widthAnchor.constraint(equalToConstant: AppStatsLayout.appColumnWidth)
        keysWidthConstraint = keysLabel.widthAnchor.constraint(equalToConstant: AppStatsLayout.keysColumnWidth)
        clicksWidthConstraint = clicksLabel.widthAnchor.constraint(equalToConstant: AppStatsLayout.clicksColumnWidth)
        scrollWidthConstraint = scrollLabel.widthAnchor.constraint(equalToConstant: AppStatsLayout.scrollColumnWidth)
        NSLayoutConstraint.activate([
            nameWidthConstraint,
            keysWidthConstraint,
            clicksWidthConstraint,
            scrollWidthConstraint
        ])

        addDividerView(after: nameLabel, divider: .appKeys)
        addDividerView(after: keysLabel, divider: .keysClicks)
        addDividerView(after: clicksLabel, divider: .clicksScroll)
    }

    func updateSortIndicator(selectedMetric: SortMetric) {
        let indicator = sortIndicator.isEmpty ? nil : sortIndicator
        keysLabel.updateIndicator(selectedMetric == .keys ? indicator : nil)
        clicksLabel.updateIndicator(selectedMetric == .clicks ? indicator : nil)
        scrollLabel.updateIndicator(selectedMetric == .scroll ? indicator : nil)
    }

    func applyColumnWidths(_ widths: AppStatsColumnWidths) {
        nameWidthConstraint.constant = widths.app
        keysWidthConstraint.constant = widths.keys
        clicksWidthConstraint.constant = widths.clicks
        scrollWidthConstraint.constant = widths.scroll
    }

    private func makeHeaderLabel(text: String, isNameColumn: Bool) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        configureHeaderLabel(label, isNameColumn: isNameColumn)
        return label
    }

    private func makeSortableHeaderLabel(text: String, metric: SortMetric) -> SortableHeaderLabel {
        let label = SortableHeaderLabel(text: text, metric: metric)
        configureHeaderLabel(label, isNameColumn: false)
        label.onClick = { [weak self] metric in
            self?.sortMetricHandler?(metric)
        }
        return label
    }

    private func configureHeaderLabel(_ label: NSTextField, isNameColumn: Bool) {
        label.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.alignment = isNameColumn ? .left : .right
        if isNameColumn {
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        } else {
            label.setContentHuggingPriority(.required, for: .horizontal)
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
    }

    private func addDividerView(after view: NSView, divider: AppStatsColumnDivider) {
        let dividerView = AppStatsColumnDividerView()
        dividerView.onDrag = { [weak self] delta in
            self?.columnResizeHandler?(divider, delta)
        }
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dividerView)
        NSLayoutConstraint.activate([
            dividerView.centerXAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: AppStatsLayout.columnSpacing / 2
            ),
            dividerView.topAnchor.constraint(equalTo: topAnchor),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.widthAnchor.constraint(equalToConstant: AppStatsLayout.dividerHitWidth)
        ])
    }
}

private final class AppStatsRowView: NSView {
    private var nameScrollView: NSScrollView!
    private var nameContainer: NSView!
    private var nameLabel: NSTextField!
    private var keysLabel: NSTextField!
    private var clicksLabel: NSTextField!
    private var scrollLabel: NSTextField!
    private var nameWidthConstraint: NSLayoutConstraint!
    private var keysWidthConstraint: NSLayoutConstraint!
    private var clicksWidthConstraint: NSLayoutConstraint!
    private var scrollWidthConstraint: NSLayoutConstraint!

    var columnResizeHandler: ((AppStatsColumnDivider, CGFloat) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: AppStatsLayout.rowHeight).isActive = true

        nameLabel = NSTextField(labelWithString: "")
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        nameLabel.textColor = .labelColor
        nameLabel.lineBreakMode = .byClipping
        nameLabel.maximumNumberOfLines = 1
        nameLabel.usesSingleLineMode = true

        nameContainer = NSView()
        nameContainer.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = true
        nameLabel.frame = .zero
        nameLabel.sizeToFit()
        nameContainer.frame = nameLabel.frame

        nameScrollView = NSScrollView()
        nameScrollView.hasHorizontalScroller = true
        nameScrollView.hasVerticalScroller = false
        nameScrollView.autohidesScrollers = true
        nameScrollView.scrollerStyle = .overlay
        nameScrollView.drawsBackground = false
        nameScrollView.borderType = .noBorder
        nameScrollView.documentView = nameContainer
        nameScrollView.translatesAutoresizingMaskIntoConstraints = false
        nameScrollView.horizontalScroller?.controlSize = .mini

        keysLabel = makeValueLabel()
        clicksLabel = makeValueLabel()
        scrollLabel = makeValueLabel()

        let stack = NSStackView(views: [nameScrollView, keysLabel, clicksLabel, scrollLabel])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = AppStatsLayout.columnSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        nameWidthConstraint = nameScrollView.widthAnchor.constraint(equalToConstant: AppStatsLayout.appColumnWidth)
        keysWidthConstraint = keysLabel.widthAnchor.constraint(equalToConstant: AppStatsLayout.keysColumnWidth)
        clicksWidthConstraint = clicksLabel.widthAnchor.constraint(equalToConstant: AppStatsLayout.clicksColumnWidth)
        scrollWidthConstraint = scrollLabel.widthAnchor.constraint(equalToConstant: AppStatsLayout.scrollColumnWidth)
        NSLayoutConstraint.activate([
            nameWidthConstraint,
            keysWidthConstraint,
            clicksWidthConstraint,
            scrollWidthConstraint,
            nameScrollView.heightAnchor.constraint(equalToConstant: AppStatsLayout.nameColumnHeight)
        ])
        addDividerView(after: nameScrollView, divider: .appKeys)
        addDividerView(after: keysLabel, divider: .keysClicks)
        addDividerView(after: clicksLabel, divider: .clicksScroll)
    }

    func update(name: String, keyPresses: String, clicks: String, scroll: String) {
        nameLabel.stringValue = name
        nameLabel.toolTip = name
        nameLabel.sizeToFit()
        nameContainer.frame = NSRect(origin: .zero, size: nameLabel.frame.size)
        nameScrollView.contentView.scroll(to: .zero)
        nameScrollView.reflectScrolledClipView(nameScrollView.contentView)
        keysLabel.stringValue = keyPresses
        clicksLabel.stringValue = clicks
        scrollLabel.stringValue = scroll
    }

    func applyColumnWidths(_ widths: AppStatsColumnWidths) {
        nameWidthConstraint.constant = widths.app
        keysWidthConstraint.constant = widths.keys
        clicksWidthConstraint.constant = widths.clicks
        scrollWidthConstraint.constant = widths.scroll
    }

    private func makeValueLabel() -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.alignment = .right
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }

    private func addDividerView(after view: NSView, divider: AppStatsColumnDivider) {
        let dividerView = AppStatsColumnDividerView()
        dividerView.onDrag = { [weak self] delta in
            self?.columnResizeHandler?(divider, delta)
        }
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dividerView)
        NSLayoutConstraint.activate([
            dividerView.centerXAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: AppStatsLayout.columnSpacing / 2
            ),
            dividerView.topAnchor.constraint(equalTo: topAnchor),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.widthAnchor.constraint(equalToConstant: AppStatsLayout.dividerHitWidth)
        ])
    }

}

private final class AppStatsColumnDividerView: NSView {
    var onDrag: ((CGFloat) -> Void)?
    private var lastDragLocationX: CGFloat?

    override var mouseDownCanMoveWindow: Bool {
        return false
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard onDrag != nil else { return nil }
        return super.hitTest(point)
    }

    override func resetCursorRects() {
        guard onDrag != nil else { return }
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }

    override func mouseDown(with event: NSEvent) {
        guard onDrag != nil else { return }
        lastDragLocationX = event.locationInWindow.x
    }

    override func mouseDragged(with event: NSEvent) {
        guard onDrag != nil, let last = lastDragLocationX else { return }
        let current = event.locationInWindow.x
        let delta = current - last
        lastDragLocationX = current
        onDrag?(delta)
    }

    override func mouseUp(with event: NSEvent) {
        lastDragLocationX = nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let inset = AppStatsLayout.dividerVerticalInset
        let lineHeight = max(0, bounds.height - (inset * 2))
        let lineRect = NSRect(
            x: (bounds.width - AppStatsLayout.dividerThickness) / 2,
            y: inset,
            width: AppStatsLayout.dividerThickness,
            height: lineHeight
        )
        NSColor.separatorColor.setFill()
        lineRect.fill()
    }
}

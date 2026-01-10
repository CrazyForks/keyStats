import Cocoa

final class HoverIconButton: NSButton {
    var padding: CGFloat = 8 {
        didSet { invalidateIntrinsicContentSize() }
    }
    var hoverBackgroundColor: NSColor = NSColor.systemGray.withAlphaComponent(0.2)
    var cornerRadius: CGFloat = 6 {
        didSet { layer?.cornerRadius = cornerRadius }
    }

    private var trackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override var intrinsicContentSize: NSSize {
        let baseSize = super.intrinsicContentSize
        return NSSize(width: baseSize.width + padding * 2, height: baseSize.height + padding * 2)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        setHovered(true)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        setHovered(false)
    }

    private func commonInit() {
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    private func setHovered(_ hovered: Bool) {
        layer?.backgroundColor = hovered ? hoverBackgroundColor.cgColor : NSColor.clear.cgColor
    }
}

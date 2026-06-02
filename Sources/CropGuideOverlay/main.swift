import Cocoa

struct GuideConfig {
    var aspectWidth: CGFloat = 9
    var aspectHeight: CGFloat = 16
    var label: String = "9:16 CROP"
    var lineWidth: CGFloat = 5
    var glowWidth: CGFloat = 18
    var lineColor = NSColor(calibratedRed: 0.0, green: 0.98, blue: 1.0, alpha: 1.0)
}

final class GuideView: NSView {
    var config = GuideConfig() {
        didSet { needsDisplay = true }
    }

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let guideWidth = min(bounds.width, bounds.height * config.aspectWidth / config.aspectHeight)
        let leftX = (bounds.width - guideWidth) / 2.0
        let rightX = leftX + guideWidth
        let shadowColor = config.lineColor.withAlphaComponent(0.52)
        let textColor = NSColor(calibratedWhite: 1.0, alpha: 0.82)

        drawVerticalLine(at: leftX, color: config.lineColor, shadowColor: shadowColor)
        drawVerticalLine(at: rightX, color: config.lineColor, shadowColor: shadowColor)
        drawHorizontalLine(from: leftX, to: rightX, y: bounds.height - 2)
        drawHorizontalLine(from: leftX, to: rightX, y: 2)
        drawLabel(config.label, centeredBetween: leftX, and: rightX)

        func drawHorizontalLine(from leftX: CGFloat, to rightX: CGFloat, y: CGFloat) {
            let path = NSBezierPath()
            path.move(to: NSPoint(x: leftX, y: y))
            path.line(to: NSPoint(x: rightX, y: y))
            config.lineColor.withAlphaComponent(0.42).setStroke()
            path.lineWidth = 2
            path.stroke()
        }

        func drawLabel(_ label: String, centeredBetween leftX: CGFloat, and rightX: CGFloat) {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 16, weight: .bold),
                .foregroundColor: textColor,
                .kern: 1.5
            ]
            let labelSize = label.size(withAttributes: attrs)
            let x = leftX + ((rightX - leftX) - labelSize.width) / 2.0
            label.draw(at: NSPoint(x: x, y: bounds.height - 38), withAttributes: attrs)
        }
    }

    private func drawVerticalLine(at x: CGFloat, color: NSColor, shadowColor: NSColor) {
        let glow = NSBezierPath()
        glow.move(to: NSPoint(x: x, y: 0))
        glow.line(to: NSPoint(x: x, y: bounds.height))
        shadowColor.setStroke()
        glow.lineWidth = config.glowWidth
        glow.stroke()

        let line = NSBezierPath()
        line.move(to: NSPoint(x: x, y: 0))
        line.line(to: NSPoint(x: x, y: bounds.height))
        color.setStroke()
        line.lineWidth = config.lineWidth
        line.stroke()
    }
}

final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class OverlayController {
    private var windows: [OverlayWindow] = []
    private var keepFrontTimer: Timer?
    private var config = GuideConfig()

    var isShowing: Bool {
        !windows.isEmpty
    }

    func show() {
        hide()
        ProcessInfo.processInfo.disableAutomaticTermination("Crop Guide Overlay should stay visible until explicitly quit")

        for screen in NSScreen.screens {
            let window = OverlayWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            let view = GuideView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.config = config

            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.sharingType = .none
            window.contentView = view
            window.orderFrontRegardless()
            windows.append(window)
        }

        keepFrontTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.windows.forEach { window in
                window.orderFrontRegardless()
                window.contentView?.needsDisplay = true
            }
        }
    }

    func hide() {
        keepFrontTimer?.invalidate()
        keepFrontTimer = nil
        windows.forEach { $0.close() }
        windows.removeAll()
    }

    func setPreset(_ preset: Preset) {
        config.aspectWidth = preset.aspectWidth
        config.aspectHeight = preset.aspectHeight
        config.label = preset.label
        if isShowing {
            show()
        }
    }
}

struct Preset {
    let label: String
    let aspectWidth: CGFloat
    let aspectHeight: CGFloat

    static let portrait916 = Preset(label: "9:16 CROP", aspectWidth: 9, aspectHeight: 16)
    static let square = Preset(label: "1:1 CROP", aspectWidth: 1, aspectHeight: 1)
    static let portrait45 = Preset(label: "4:5 CROP", aspectWidth: 4, aspectHeight: 5)
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlay = OverlayController()
    private var statusItem: NSStatusItem?
    private let showHideItem = NSMenuItem(title: "Hide Guides", action: #selector(toggleGuides), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMenu()
        overlay.show()
        updateMenuTitle()
    }

    private func configureMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.title = "⌖"
        item.button?.toolTip = "Crop Guide Overlay"

        let menu = NSMenu()
        showHideItem.target = self
        menu.addItem(showHideItem)
        menu.addItem(NSMenuItem.separator())

        let portraitItem = NSMenuItem(title: "9:16 Center Crop", action: #selector(usePortrait916), keyEquivalent: "")
        portraitItem.target = self
        menu.addItem(portraitItem)

        let squareItem = NSMenuItem(title: "1:1 Center Crop", action: #selector(useSquare), keyEquivalent: "")
        squareItem.target = self
        menu.addItem(squareItem)

        let portrait45Item = NSMenuItem(title: "4:5 Center Crop", action: #selector(usePortrait45), keyEquivalent: "")
        portrait45Item.target = self
        menu.addItem(portrait45Item)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
    }

    @objc private func toggleGuides() {
        overlay.isShowing ? overlay.hide() : overlay.show()
        updateMenuTitle()
    }

    @objc private func usePortrait916() {
        overlay.setPreset(.portrait916)
    }

    @objc private func useSquare() {
        overlay.setPreset(.square)
    }

    @objc private func usePortrait45() {
        overlay.setPreset(.portrait45)
    }

    @objc private func quit() {
        overlay.hide()
        NSApp.terminate(nil)
    }

    private func updateMenuTitle() {
        showHideItem.title = overlay.isShowing ? "Hide Guides" : "Show Guides"
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

import Cocoa
import ServiceManagement

struct Preset {
    let label: String
    let width: CGFloat
    let height: CGFloat
    static let all = [Preset(label: "9:16", width: 9, height: 16), Preset(label: "1:1", width: 1, height: 1), Preset(label: "4:5", width: 4, height: 5)]
}

struct GuideConfig {
    var preset = Preset.all[0]
    var color = NSColor.cyan
    var opacity: CGFloat = 0.85
}

final class GuideView: NSView {
    var config = GuideConfig() { didSet { needsDisplay = true } }
    override var isOpaque: Bool { false }
    override func draw(_ dirtyRect: NSRect) {
        let rect = fittedGuide(in: bounds, aspectWidth: config.preset.width, aspectHeight: config.preset.height)
        let path = NSBezierPath(rect: rect)
        config.color.withAlphaComponent(config.opacity * 0.25).setStroke()
        path.lineWidth = 14
        path.stroke()
        config.color.withAlphaComponent(config.opacity).setStroke()
        path.lineWidth = 4
        path.stroke()
        let label = config.preset.label + " CROP"
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 16, weight: .bold), .foregroundColor: config.color.withAlphaComponent(config.opacity)]
        let size = label.size(withAttributes: attrs)
        label.draw(at: NSPoint(x: rect.midX - size.width / 2, y: rect.maxY - 30), withAttributes: attrs)
    }
}

final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

func displayKey(_ screen: NSScreen) -> String {
    let id = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    if let uuid = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() {
        return CFUUIDCreateString(nil, uuid) as String
    }
    return "display-\(id)"
}

final class OverlayController {
    private var windows: [String: OverlayWindow] = [:]
    private let defaults = UserDefaults.standard
    var isShowing: Bool { didSet { defaults.set(isShowing, forKey: "showGuides"); reconcile() } }
    var presetIndex: Int { didSet { defaults.set(presetIndex, forKey: "preset"); reconcile() } }
    var selectedDisplays: Set<String> { didSet { defaults.set(Array(selectedDisplays), forKey: "displays"); reconcile() } }
    var opacity: CGFloat { didSet { defaults.set(Double(opacity), forKey: "opacity"); reconcile() } }
    var colorIndex: Int { didSet { defaults.set(colorIndex, forKey: "color"); reconcile() } }
    static let colors: [(String, NSColor)] = [("Cyan", .cyan), ("Yellow", .yellow), ("White", .white), ("Magenta", .magenta)]

    init() {
        isShowing = defaults.object(forKey: "showGuides") as? Bool ?? true
        presetIndex = min(2, max(0, defaults.integer(forKey: "preset")))
        selectedDisplays = Set(defaults.stringArray(forKey: "displays") ?? ["all"])
        opacity = CGFloat(min(1, max(0.25, defaults.object(forKey: "opacity") as? Double ?? 0.85)))
        colorIndex = min(Self.colors.count - 1, max(0, defaults.integer(forKey: "color")))
    }
    func reconcile() {
        let screens = isShowing ? NSScreen.screens.filter { selectedDisplays.contains("all") || selectedDisplays.contains(displayKey($0)) } : []
        let keys = Set(screens.map(displayKey))
        for key in Set(windows.keys).subtracting(keys) { windows.removeValue(forKey: key)?.close() }
        for screen in screens {
            let key = displayKey(screen)
            let window: OverlayWindow
            if let existing = windows[key] { window = existing }
            else {
                window = OverlayWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
                window.backgroundColor = .clear
                window.isOpaque = false
                window.hasShadow = false
                window.ignoresMouseEvents = true
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
                // Legacy hint only. Modern display captures can include this window.
                window.sharingType = .none
                window.contentView = GuideView(frame: NSRect(origin: .zero, size: screen.frame.size))
                windows[key] = window
            }
            window.setFrame(screen.frame, display: true)
            (window.contentView as? GuideView)?.config = GuideConfig(preset: Preset.all[presetIndex], color: Self.colors[colorIndex].1, opacity: opacity)
            window.orderFrontRegardless()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let overlay = OverlayController()
    private var statusItem: NSStatusItem!
    private var legacyAgent: URL { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents/com.10xoss.crop-guide-overlay.plist") }
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "Crop Guide"
        statusItem.button?.toolTip = "Crop Guide — hide guides before recording unless capture exclusion has been verified"
        let menu = NSMenu(); menu.delegate = self; statusItem.menu = menu
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(screensChanged), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        overlay.reconcile()
    }
    @objc private func screensChanged() { overlay.reconcile() }
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        func item(_ title: String, _ action: Selector, key: String = "", on: Bool = false, value: Any? = nil) -> NSMenuItem {
            let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
            i.target = self; i.state = on ? .on : .off; i.representedObject = value
            return i
        }
        menu.addItem(item(overlay.isShowing ? "Hide Guides" : "Show Guides", #selector(toggleGuides), key: "h"))
        menu.addItem(item("Capture Compatibility…", #selector(compatibility)))
        menu.addItem(.separator())
        for (index, preset) in Preset.all.enumerated() {
            menu.addItem(item(preset.label + " Center Crop", #selector(preset(_:)), on: overlay.presetIndex == index, value: index))
        }
        let displayMenu = NSMenu()
        displayMenu.addItem(item("All Displays", #selector(display(_:)), on: overlay.selectedDisplays.contains("all"), value: "all"))
        for screen in NSScreen.screens {
            let key = displayKey(screen)
            displayMenu.addItem(item(screen.localizedName, #selector(display(_:)), on: overlay.selectedDisplays.contains("all") || overlay.selectedDisplays.contains(key), value: key))
        }
        let displays = NSMenuItem(title: "Displays", action: nil, keyEquivalent: ""); displays.submenu = displayMenu; menu.addItem(displays)
        let style = NSMenu()
        for (index, color) in OverlayController.colors.enumerated() { style.addItem(item(color.0, #selector(color(_:)), on: overlay.colorIndex == index, value: index)) }
        style.addItem(.separator())
        for opacity in [0.4, 0.65, 0.85, 1.0] { style.addItem(item("Opacity \(Int(opacity * 100))%", #selector(opacity(_:)), on: abs(Double(overlay.opacity) - opacity) < 0.01, value: opacity)) }
        let styleItem = NSMenuItem(title: "Guide Appearance", action: nil, keyEquivalent: ""); styleItem.submenu = style; menu.addItem(styleItem)
        menu.addItem(.separator())
        let service = SMAppService.mainApp
        let legacy = FileManager.default.fileExists(atPath: legacyAgent.path)
        menu.addItem(item(service.status == .requiresApproval ? "Launch at Login (Approval Required)…" : "Launch at Login", #selector(login), on: legacy || service.status == .enabled))
        menu.addItem(item("Quit Crop Guide Overlay", #selector(quit), key: "q"))
    }
    @objc private func toggleGuides() { overlay.isShowing.toggle() }
    @objc private func preset(_ sender: NSMenuItem) { if let index = sender.representedObject as? Int { overlay.presetIndex = index } }
    @objc private func color(_ sender: NSMenuItem) { if let index = sender.representedObject as? Int { overlay.colorIndex = index } }
    @objc private func opacity(_ sender: NSMenuItem) { if let value = sender.representedObject as? Double { overlay.opacity = CGFloat(value) } }
    @objc private func display(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        var selected = overlay.selectedDisplays
        if key == "all" { selected = ["all"] }
        else {
            if selected.contains("all") { selected = Set(NSScreen.screens.map(displayKey)) }
            if selected.contains(key) { selected.remove(key) } else { selected.insert(key) }
        }
        overlay.selectedDisplays = selected
    }
    @objc private func compatibility() {
        let alert = NSAlert()
        alert.messageText = "Guides may appear in recordings"
        alert.informativeText = "Full-display captures can include these guides. Use your recorder’s application/window exclusion where supported, and inspect a short exported test with your exact source and macOS version. Otherwise choose Hide Guides (⌘H in this menu) before recording. No recorder combination is currently certified."
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Hide Guides")
        if alert.runModal() == .alertSecondButtonReturn { overlay.isShowing = false }
    }
    @objc private func login() {
        do {
            let wasLegacy = FileManager.default.fileExists(atPath: legacyAgent.path)
            if FileManager.default.fileExists(atPath: legacyAgent.path) {
                // Disable future legacy launches without terminating this running app.
                let process = Process(); process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
                process.arguments = ["disable", "gui/\(getuid())/com.10xoss.crop-guide-overlay"]
                try process.run(); process.waitUntilExit()
                guard process.terminationStatus == 0 else { throw CocoaError(.fileWriteUnknown) }
                try FileManager.default.removeItem(at: legacyAgent)
            }
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else if SMAppService.mainApp.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
            else if !FileManager.default.fileExists(atPath: legacyAgent.path) {
                // A legacy removal is an opt-out; a later toggle can enable the modern item.
                if wasLegacy { return }
                try SMAppService.mainApp.register()
            }
        } catch { let alert = NSAlert(error: error); alert.runModal() }
    }
    @objc private func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

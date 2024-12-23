import Cocoa

class ClipboardManager {
    // Singleton instance to ensure only one instance exists
    static let shared = ClipboardManager()
    
    // Store clipboard history
    private var clipboardHistory: [String] = []
    
    // Maximum number of items to store
    private let maxHistoryItems = 10
    
    private init() {
        // Private initializer to prevent creating multiple instances
    }
    
    // Capture and store clipboard content
    func captureClipboard() {
        let pasteboard = NSPasteboard.general
        guard let clipboardString = pasteboard.string(forType: .string),
              !clipboardString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Remove duplicate if exists
        if let index = clipboardHistory.firstIndex(of: clipboardString) {
            clipboardHistory.remove(at: index)
        }
        
        // Add to the front of history
        clipboardHistory.insert(clipboardString, at: 0)
        
        // Trim to max history
        if clipboardHistory.count > maxHistoryItems {
            clipboardHistory = Array(clipboardHistory.prefix(maxHistoryItems))
        }
        
        print("Clipboard History: \(clipboardHistory)")
    }
    
    // Get current clipboard history
    func getClipboardHistory() -> [String] {
        return clipboardHistory
    }
    
    // Clear clipboard history
    func clearClipboardHistory() {
        clipboardHistory.removeAll()
    }
}

// Status Bar Controller
class ClipboardStatusBarController {
    private var statusItem: NSStatusItem
    private var statusBarMenu: NSMenu
    
    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarMenu = NSMenu()
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        // Set status bar icon
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard History")
        }
        
        // Create and set menu
        updateMenu()
        statusItem.menu = statusBarMenu
    }
    
    func updateMenu() {
        statusBarMenu.removeAllItems()
        
        // Clipboard history items
        let history = ClipboardManager.shared.getClipboardHistory()
        
        if history.isEmpty {
            let emptyItem = NSMenuItem(title: "No clipboard history", action: nil, keyEquivalent: "")
            statusBarMenu.addItem(emptyItem)
        } else {
            for (index, item) in history.enumerated() {
                let menuItem = NSMenuItem(title: truncateString(item, maxLength: 50), action: #selector(copyHistoryItem(_:)), keyEquivalent: "")
                menuItem.tag = index
                menuItem.target = self
                statusBarMenu.addItem(menuItem)
            }
            
            statusBarMenu.addItem(NSMenuItem.separator())
        }
        
        // Clear history option
        let clearHistoryItem = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
        clearHistoryItem.target = self
        statusBarMenu.addItem(clearHistoryItem)
        
        // Quit option
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        statusBarMenu.addItem(quitItem)
    }
    
    @objc private func copyHistoryItem(_ sender: NSMenuItem) {
        let history = ClipboardManager.shared.getClipboardHistory()
        guard sender.tag < history.count else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(history[sender.tag], forType: .string)
    }
    
    @objc private func clearHistory() {
        ClipboardManager.shared.clearClipboardHistory()
        updateMenu()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func truncateString(_ string: String, maxLength: Int) -> String {
        guard string.count > maxLength else { return string }
        return String(string.prefix(maxLength)) + "..."
    }
}

// App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: ClipboardStatusBarController?
    private var pasteboardTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup status bar
        statusBarController = ClipboardStatusBarController()
        
        // Start monitoring clipboard
        startClipboardMonitoring()
    }
    
    private func startClipboardMonitoring() {
        // Check clipboard every 0.5 seconds
        pasteboardTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            ClipboardManager.shared.captureClipboard()
            self?.statusBarController?.updateMenu()
        }
    }
}

import AppKit
extension NSTextView {
    open override func menu(for event: NSEvent?) -> NSMenu? {
        let menu = super.menu(for: event!)
        
        // Add Clipboard History menu item
        let clipboardHistoryItem = NSMenuItem(
            title: "Clipboard History",
            action: #selector(showClipboardHistory),
            keyEquivalent: ""
        )
        clipboardHistoryItem.target = self
        
        menu?.addItem(NSMenuItem.separator())
        menu?.addItem(clipboardHistoryItem)
        
        return menu
    }
    
    @objc func showClipboardHistory() {
        let history = ClipboardManager.shared.getClipboardHistory()
        
        // Create a popup menu for clipboard history
        let historyMenu = NSMenu()
        for (index, item) in history.enumerated() {
            let menuItem = NSMenuItem(title: item, action: #selector(pasteClipboardItem(_:)), keyEquivalent: "")
            menuItem.tag = index
            menuItem.target = self
            historyMenu.addItem(menuItem)
        }
        
        // Show menu as a popup
        NSMenu.popUpContextMenu(historyMenu, with: NSApp.currentEvent!, for: self)
    }
    
    @objc func pasteClipboardItem(_ sender: NSMenuItem) {
        let history = ClipboardManager.shared.getClipboardHistory()
        guard sender.tag < history.count else { return }
        
        // Paste selected clipboard history item
        insertText(history[sender.tag])
    }
}

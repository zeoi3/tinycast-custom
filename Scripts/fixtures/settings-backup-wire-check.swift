import Foundation
@testable import Tinycast

@main
struct BackupWireCheck {
    static func main() throws {
        let id = "f51bca7b-a67c-4df7-9a2a-2bd4f5f70d0d"
        let binding = HotKeyBinding.combo(KeyShortcut(carbonKeyCode: 0, carbonModifiers: 256))
        var hotkeys = SettingsBackup.HotkeyBackup()
        hotkeys.appleShortcuts = [id: binding]
        var backup = SettingsBackup()
        backup.hotkeys = hotkeys
        let data = try JSONEncoder().encode(backup)
        let restored = try JSONDecoder().decode(SettingsBackup.self, from: data)
        precondition(restored.hotkeys?.appleShortcuts?[id] == binding)
        let old = try JSONDecoder().decode(SettingsBackup.self, from: Data("{\"hotkeys\":{}}".utf8))
        precondition(old.hotkeys?.appleShortcuts == nil)
        print("Actual SettingsBackup module: Apple shortcut binding round-trip and legacy decode passed")
    }
}

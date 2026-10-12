import Foundation

/// The product boundary is independent of preferences, backups and upstream feature defaults.
enum ProductProfile {
    static let featureNames: Set<String> = ["applications", "customCommands", "quicklinks", "appleShortcuts"]
    static let kinds: Set<String> = ["application", "command", "customCommand", "quicklink", "appleShortcut"]
    static let settingsTabs: Set<String> = [
        "general", "applications", "commands", "quicklinks", "appleShortcuts",
        "permissions", "backup", "about", "ai", "fallbacks"
    ]
    static let paletteModes: Set<String> = [
        "launcher", "calculatorHistory", "customCommandEditor", "customCommands",
        "quicklinks", "quicklinkEditor"
    ]
    static let commands: Set<String> = [
        "command:calculator-history", "command:open-in-browser",
        "command:create-custom-command", "command:search-custom-commands",
        "command:create-quicklink", "command:search-quicklinks",
        "command:import-quicklinks", "command:export-quicklinks",
        "command:export-settings", "command:import-settings", "command:import-from-raycast",
        "command:settings", "command:about", "command:quit"
    ]
    static let excludedSettingsRows: Set<String> = [
        "Automatically check for updates", "Support reminders", "Check for Updates", "Support"
    ]
    static let backupCategories: Set<String> = ["configuration", "learning"]

    static func allowsFeature(_ name: String) -> Bool { featureNames.contains(name) }
    static func allowsCommand(_ id: String) -> Bool { commands.contains(id) }
    static func allowsHotKey(_ key: String) -> Bool {
        if key == "hotkey.togglePalette" { return true }
        if key.hasPrefix("hotkey.command:") {
            return allowsCommand(String(key.dropFirst("hotkey.".count)))
        }
        return ["hotkey.app.", "hotkey.customCommand.", "hotkey.quicklink.", "hotkey.appleShortcut."]
            .contains { key.hasPrefix($0) }
    }
}

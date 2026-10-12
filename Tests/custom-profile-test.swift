import Foundation

@main
struct CustomProfileTest {
    static func main() {
        for key in [
            "clipboard", "clipboardTextSearch", "ai", "mcp", "extensions", "notes", "calendar", "dictation"
        ] {
            precondition(!ProductProfile.allowsFeature(key), "Disabled feature escaped: \(key)")
        }
        for key in [
            "hotkey.command:clipboard-history", "hotkey.dictation", "hotkey.extensionCommand:test",
            "hotkey.windowCommand:left", "hotkey.pane:preferences", "hotkey.command:unknown"
        ] {
            precondition(!ProductProfile.allowsHotKey(key))
        }
        for key in ["hotkey.togglePalette", "hotkey.app:bad"] {
            if key == "hotkey.togglePalette" {
                precondition(ProductProfile.allowsHotKey(key))
            } else {
                precondition(!ProductProfile.allowsHotKey(key))
            }
        }
        for key in [
            "hotkey.app.com.apple.Safari", "hotkey.quicklink.123", "hotkey.appleShortcut.123",
            "hotkey.customCommand.123", "hotkey.command:calculator-history"
        ] {
            precondition(ProductProfile.allowsHotKey(key))
        }
        precondition(ProductProfile.backupCategories == ["configuration", "learning"])
        precondition(!ProductProfile.paletteModes.contains("clipboard"))
        precondition(!ProductProfile.settingsTabs.contains("extensions"))
        precondition(WebAI.website("file:///tmp/prompt") == nil)
        precondition(WebAI.website("javascript:alert(1)") == nil)
        precondition(WebAI.website("https://name:secret@example.com") == nil)
        let prompt = "你好 & why? 50% + # / 🐈\n第二行"
        var components = URLComponents(string: "tinycast-custom://web-ai")!
        components.queryItems = [
            URLQueryItem(name: "site", value: "https://chatgpt.com/"),
            URLQueryItem(name: "prompt", value: prompt)
        ]
        let request = WebAI.request(components.string!)!
        precondition(request.prompt == prompt)
        precondition(request.site == WebAI.defaultSite)
        precondition(WebAI.site(in: WebAI.template(site: WebAI.defaultSite)) == WebAI.defaultSite)
        precondition(WebAI.request("tinycast-custom://web-ai?site=file:///tmp/a&prompt=hi") == nil)
        precondition(WebAI.request("tinycast-custom://web-ai?site=https://chatgpt.com/&prompt=%20") == nil)
        print("Custom profile and web AI request checks passed")
    }
}

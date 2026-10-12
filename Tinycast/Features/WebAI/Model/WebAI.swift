import Foundation

/// Stored as an ordinary quicklink, so aliases, hotkeys, backup and query arguments stay shared.
enum WebAI {
    static let quicklinkID = UUID(uuidString: "91613206-3C87-4E75-98D5-465C71600687")!
    static let defaultSite = URL(string: "https://chatgpt.com/")!
    static let presets = [
        ("ChatGPT", "https://chatgpt.com/"),
        ("Claude", "https://claude.ai/"),
        ("Gemini", "https://gemini.google.com/")
    ]

    static func website(_ raw: String) -> URL? {
        guard let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)),
            ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
            let host = url.host, !host.isEmpty, url.user == nil, url.password == nil
        else { return nil }
        return url
    }

    static func template(site: URL) -> String {
        var components = URLComponents()
        components.scheme = "tinycast-custom"
        components.host = "web-ai"
        components.queryItems = [URLQueryItem(name: "site", value: site.absoluteString)]
        return components.string! + "&prompt={argument name=\"问题\"}"
    }

    static func site(in template: String) -> URL? {
        guard let components = URLComponents(string: template),
            components.scheme == "tinycast-custom", components.host == "web-ai",
            let raw = components.queryItems?.first(where: { $0.name == "site" })?.value
        else { return nil }
        return website(raw)
    }

    static func request(_ expanded: String) -> (site: URL, prompt: String)? {
        guard let site = site(in: expanded), let components = URLComponents(string: expanded),
            let prompt = components.queryItems?.first(where: { $0.name == "prompt" })?.value,
            !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return (site, prompt)
    }
}

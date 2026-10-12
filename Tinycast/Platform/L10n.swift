import Foundation

/// The custom edition defaults to Simplified Chinese; untranslated keys remain readable English.
enum L10n {
    private static let bundle: Bundle = {
        guard let path = Bundle.main.path(forResource: "zh-Hans", ofType: "lproj"),
            let bundle = Bundle(path: path)
        else { return .main }
        return bundle
    }()

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key), locale: Locale(identifier: "zh-Hans"), arguments: arguments)
    }

    static func tr(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
}

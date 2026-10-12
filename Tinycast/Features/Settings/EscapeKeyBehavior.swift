import Foundation

/// What Escape does on the palette once the search field it would have cleared is already empty.
enum EscapeKeyBehavior: String, CaseIterable, Identifiable, Sendable {
    case navigateBackOrClose
    case closeAndPopToRoot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .navigateBackOrClose: return L10n.tr("Navigate back or close window")
        case .closeAndPopToRoot: return L10n.tr("Close window and pop to root")
        }
    }
}

import Foundation

enum DisplayMode: String, Sendable {
    /// Free-floating Liquid Glass panel.
    case floating
    /// Menu-bar item with tournament name beside the icon; top-10 popover on left click.
    case compact

    static let defaultsKey = "displayMode"

    static var current: DisplayMode {
        let raw = UserDefaults.standard.string(forKey: defaultsKey) ?? ""
        return DisplayMode(rawValue: raw) ?? .floating
    }

    static func setCurrent(_ mode: DisplayMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: defaultsKey)
    }

    var oppositeLabel: String {
        switch self {
        case .floating: "Switch to Compact"
        case .compact: "Switch to Floating"
        }
    }
}

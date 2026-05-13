import Foundation
import Observation

@MainActor
@Observable
final class StarredPlayersStore {
    private(set) var ids: Set<String>
    private let defaults: UserDefaults
    private let key = "starred.player.ids"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.array(forKey: key) as? [String] ?? []
        self.ids = Set(stored)
    }

    func isStarred(_ id: String) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: String) {
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        persist()
    }

    private func persist() {
        defaults.set(Array(ids), forKey: key)
    }
}

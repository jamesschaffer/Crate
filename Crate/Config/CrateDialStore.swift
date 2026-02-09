import Foundation

/// Reads and writes the user's Crate Dial position to UserDefaults.
struct CrateDialStore: Sendable {

    private static let key = "crateDialPosition"

    /// Current dial position; defaults to `.mixedCrate` if never set.
    var position: CrateDialPosition {
        get {
            let raw = UserDefaults.standard.integer(forKey: Self.key)
            return CrateDialPosition(rawValue: raw) ?? .mixedCrate
        }
        nonmutating set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Self.key)
        }
    }
}

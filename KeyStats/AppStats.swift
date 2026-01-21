import Foundation

struct AppStats: Codable {
    var bundleId: String
    var displayName: String
    var keyPresses: Int
    var leftClicks: Int
    var rightClicks: Int
    var scrollDistance: Double

    init(bundleId: String, displayName: String) {
        self.bundleId = bundleId
        self.displayName = displayName
        self.keyPresses = 0
        self.leftClicks = 0
        self.rightClicks = 0
        self.scrollDistance = 0
    }

    var totalClicks: Int {
        return leftClicks + rightClicks
    }

    var hasActivity: Bool {
        return keyPresses > 0 || leftClicks > 0 || rightClicks > 0 || scrollDistance > 0
    }

    mutating func updateDisplayName(_ name: String) {
        guard !name.isEmpty else { return }
        displayName = name
    }

    mutating func recordKeyPress() {
        keyPresses += 1
    }

    mutating func recordLeftClick() {
        leftClicks += 1
    }

    mutating func recordRightClick() {
        rightClicks += 1
    }

    mutating func addScrollDistance(_ distance: Double) {
        scrollDistance += abs(distance)
    }
}

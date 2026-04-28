import Foundation

enum ViewerSlideshowIntervalFormatter {
    static func string(for seconds: Double) -> String {
        if seconds.rounded() == seconds {
            return "\(Int(seconds))"
        }

        return String(format: "%.1f", seconds)
    }
}

import Foundation

enum PlaybackSpeed: Float, CaseIterable, Identifiable {
    case x0_5  = 0.5
    case x0_75 = 0.75
    case x1_0  = 1.0
    case x1_25 = 1.25
    case x1_5  = 1.5
    case x2_0  = 2.0

    var id: Float { rawValue }

    var label: String {
        switch self {
        case .x0_5:  return "0.5x"
        case .x0_75: return "0.75x"
        case .x1_0:  return "1x"
        case .x1_25: return "1.25x"
        case .x1_5:  return "1.5x"
        case .x2_0:  return "2x"
        }
    }

    static func closest(to value: Float) -> PlaybackSpeed? {
        allCases.first(where: { abs($0.rawValue - value) < 0.01 })
    }
}

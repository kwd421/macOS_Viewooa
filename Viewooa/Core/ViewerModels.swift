import AppKit
import SwiftUI

enum FitMode: CaseIterable, Equatable, Identifiable {
    case height
    case width
    case all

    var id: Self { self }

    var title: String {
        switch self {
        case .height:
            "Fit Height"
        case .width:
            "Fit Width"
        case .all:
            "Fit All"
        }
    }

    var shortTitle: String {
        switch self {
        case .height:
            "Height"
        case .width:
            "Width"
        case .all:
            "All"
        }
    }
}

enum ZoomMode: Equatable {
    case fit(FitMode)
    case actualSize
    case custom(CGFloat)

    var isFit: Bool {
        if case .fit = self {
            return true
        }

        return false
    }
}

enum ViewerPageLayout: CaseIterable, Equatable, Identifiable {
    case single
    case spread
    case verticalStrip

    var id: Self { self }

    var title: String {
        switch self {
        case .single:
            "Single Page"
        case .spread:
            "Two Pages"
        case .verticalStrip:
            "Vertical Strip"
        }
    }

    var shortTitle: String {
        switch self {
        case .single:
            "Single"
        case .spread:
            "2-Up"
        case .verticalStrip:
            "Webtoon"
        }
    }
}

enum ViewerPageLayoutResolver {
    static func spreadIndexes(currentIndex: Int, itemCount: Int, coverModeEnabled: Bool) -> [Int] {
        guard itemCount > 0 else { return [] }

        if coverModeEnabled, currentIndex == 0 {
            return [0]
        }

        let minimumPairIndex = coverModeEnabled ? 1 : 0
        let relativeIndex = max(0, currentIndex - minimumPairIndex)
        let pairStartIndex = minimumPairIndex + (relativeIndex / 2) * 2
        let pairEndIndex = min(pairStartIndex + 1, itemCount - 1)
        return Array(pairStartIndex...pairEndIndex)
    }
}

enum SpreadDirection: CaseIterable, Equatable, Identifiable {
    case leftToRight
    case rightToLeft

    var id: Self { self }

    var title: String {
        switch self {
        case .leftToRight:
            "Left to Right"
        case .rightToLeft:
            "Right to Left"
        }
    }

    var shortTitle: String {
        switch self {
        case .leftToRight:
            "L-R"
        case .rightToLeft:
            "R-L"
        }
    }
}

enum ImagePostProcessingOption: String, CaseIterable, Equatable, Identifiable {
    case sharpen
    case smooth
    case denoise
    case contrast

    var id: Self { self }

    var title: String {
        switch self {
        case .sharpen:
            "Sharpen"
        case .smooth:
            "Smooth"
        case .denoise:
            "Denoise"
        case .contrast:
            "Contrast"
        }
    }
}

struct ImageMetadataRow: Identifiable, Equatable {
    let label: String
    let value: String

    var id: String { label }
}

struct ViewerTransientNotice: Identifiable, Equatable {
    let id = UUID()
    let message: String
}

enum ViewerZoom {
    static let step: CGFloat = 1.25
    static let minimumScale: CGFloat = 0.05
    static let maximumScale: CGFloat = 8.0
}

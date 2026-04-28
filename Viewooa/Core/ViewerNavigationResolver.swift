import Foundation

enum ViewerNavigationResolver {
    static func nextIndex(
        currentIndex: Int,
        itemCount: Int,
        layout: ViewerPageLayout,
        coverModeEnabled: Bool
    ) -> Int {
        guard layout == .spread else { return currentIndex + 1 }

        let currentSpreadStart = ViewerPageLayoutResolver.spreadIndexes(
            currentIndex: currentIndex,
            itemCount: itemCount,
            coverModeEnabled: coverModeEnabled
        ).first ?? currentIndex
        return currentSpreadStart + (coverModeEnabled && currentSpreadStart == 0 ? 1 : 2)
    }

    static func previousIndex(
        currentIndex: Int,
        itemCount: Int,
        layout: ViewerPageLayout,
        coverModeEnabled: Bool
    ) -> Int {
        guard layout == .spread else { return currentIndex - 1 }

        let currentSpreadStart = ViewerPageLayoutResolver.spreadIndexes(
            currentIndex: currentIndex,
            itemCount: itemCount,
            coverModeEnabled: coverModeEnabled
        ).first ?? currentIndex

        if coverModeEnabled, currentSpreadStart <= 1 {
            return 0
        }

        let minimumPairIndex = coverModeEnabled ? 1 : 0
        return max(minimumPairIndex, currentSpreadStart - 2)
    }
}

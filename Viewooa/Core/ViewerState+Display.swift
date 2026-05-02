import AppKit

extension ViewerState {
    func rotateClockwise() {
        rotationQuarterTurns = (rotationQuarterTurns + 1) % 4
    }

    func toggleMetadataVisibility() {
        isMetadataVisible.toggle()
    }

    func setPageLayout(_ layout: ViewerPageLayout) {
        pageLayout = layout
        fitToWindow(layout == .verticalStrip ? .width : nil)
        restartSlideshowIfNeeded()
    }

    func setSpreadDirection(_ direction: SpreadDirection) {
        spreadDirection = direction
    }

    func toggleCoverMode() {
        isCoverModeEnabled.toggle()
        fitToWindow()
    }

    func togglePostProcessing(_ option: ImagePostProcessingOption) {
        if postProcessingOptions.contains(option) {
            postProcessingOptions.remove(option)
        } else {
            postProcessingOptions.insert(option)
        }
    }

    func clearPostProcessing() {
        postProcessingOptions.removeAll()
    }

    var imageMetadataRows: [ImageMetadataRow] {
        ViewerImageMetadataReader.rows(
            for: currentImageURL,
            currentResolvedImage: currentResolvedImage,
            index: index,
            isViewingPDF: isViewingPDF
        )
    }

    var displayImageURLs: [URL] {
        guard let index else { return [] }
        guard index.isValid else { return [] }

        if isViewingPDF {
            return pdfDocument?.pageIndexes(
                currentIndex: index.currentIndex,
                layout: pageLayout,
                spreadDirection: spreadDirection,
                coverModeEnabled: isCoverModeEnabled
            ).map { index.imageURLs[$0] } ?? []
        }

        switch pageLayout {
        case .single:
            return index.currentURL.map { [$0] } ?? []
        case .spread:
            let indexes = Self.spreadIndexes(
                currentIndex: index.currentIndex,
                imageCount: index.imageURLs.count,
                coverModeEnabled: isCoverModeEnabled
            )
            let orderedIndexes = spreadDirection == .leftToRight ? indexes : indexes.reversed()
            return orderedIndexes.map { index.imageURLs[$0] }
        case .verticalStrip:
            return index.imageURLs
        }
    }

    var displayResolvedImages: [NSImage]? {
        guard isViewingPDF,
              let index,
              let pdfDocument else { return nil }

        return pdfDocument.pageIndexes(
            currentIndex: index.currentIndex,
            layout: pageLayout,
            spreadDirection: spreadDirection,
            coverModeEnabled: isCoverModeEnabled
        ).compactMap { pdfDocument.image(at: $0) }
    }

    var isViewingPDF: Bool {
        pdfDocument != nil
    }

    static func spreadIndexes(currentIndex: Int, imageCount: Int, coverModeEnabled: Bool) -> [Int] {
        ViewerPageLayoutResolver.spreadIndexes(
            currentIndex: currentIndex,
            itemCount: imageCount,
            coverModeEnabled: coverModeEnabled
        )
    }
}

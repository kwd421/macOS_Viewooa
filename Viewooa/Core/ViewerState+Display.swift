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
            return [index.imageURLs[index.currentIndex]]
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

    var previousPreviewImageURL: URL? {
        guard pageLayout == .single,
              !isViewingPDF,
              let index else { return nil }

        let previousIndex = index.currentIndex - 1
        guard index.imageURLs.indices.contains(previousIndex) else { return nil }
        return index.imageURLs[previousIndex]
    }

    var nextPreviewImageURL: URL? {
        guard pageLayout == .single,
              !isViewingPDF,
              let index else { return nil }

        let nextIndex = index.currentIndex + 1
        guard index.imageURLs.indices.contains(nextIndex) else { return nil }
        return index.imageURLs[nextIndex]
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

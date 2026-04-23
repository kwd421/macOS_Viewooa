import Foundation

struct ImageViewportState: Equatable {
    var imageURL: URL?
    var imageURLs: [URL]
    var zoomMode: ZoomMode
    var rotationQuarterTurns: Int
    var pageLayout: ViewerPageLayout
    var postProcessingOptions: Set<ImagePostProcessingOption>

    init(
        imageURL: URL? = nil,
        imageURLs: [URL]? = nil,
        zoomMode: ZoomMode = .fit(.all),
        rotationQuarterTurns: Int = 0,
        pageLayout: ViewerPageLayout = .single,
        postProcessingOptions: Set<ImagePostProcessingOption> = []
    ) {
        self.imageURL = imageURL
        self.imageURLs = imageURLs ?? imageURL.map { [$0] } ?? []
        self.zoomMode = zoomMode
        self.rotationQuarterTurns = rotationQuarterTurns
        self.pageLayout = pageLayout
        self.postProcessingOptions = postProcessingOptions
    }
}

import Foundation

struct ImageViewportState: Equatable {
    var imageURL: URL?
    var zoomMode: ZoomMode
    var rotationQuarterTurns: Int

    init(imageURL: URL? = nil, zoomMode: ZoomMode = .fit, rotationQuarterTurns: Int = 0) {
        self.imageURL = imageURL
        self.zoomMode = zoomMode
        self.rotationQuarterTurns = rotationQuarterTurns
    }
}

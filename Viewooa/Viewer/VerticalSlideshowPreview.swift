import SwiftUI

struct VerticalSlideshowPreview: View {
    let intervalSeconds: Double

    private let previewSize = CGSize(width: 42, height: 30)
    private let pageSize = CGSize(width: 24, height: 18)
    private let pageGap: CGFloat = 5

    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = animationPhase(at: timeline.date)

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.white.opacity(0.08))

                ForEach(-2..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(.white.opacity(index.isMultiple(of: 2) ? 0.84 : 0.62))
                        .overlay(alignment: .top) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(.black.opacity(0.12))
                                .frame(width: pageSize.width - 8, height: 2.5)
                                .padding(.top, 4)
                        }
                        .frame(width: pageSize.width, height: pageSize.height)
                        .offset(y: CGFloat(index) * (pageSize.height + pageGap) + phase)
                }

                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.20)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 8)
                }
            }
            .frame(width: previewSize.width, height: previewSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.white.opacity(0.14))
            }
            .accessibilityLabel("Vertical slideshow motion preview")
        }
    }

    private func animationPhase(at date: Date) -> CGFloat {
        let clampedSeconds = max(intervalSeconds, ViewerState.minimumSlideshowIntervalSeconds)
        let cycle = pageSize.height + pageGap
        let previewPointsPerSecond = CGFloat(640.0 / clampedSeconds) / 18
        let progress = date.timeIntervalSinceReferenceDate * previewPointsPerSecond
        return CGFloat(progress.truncatingRemainder(dividingBy: Double(cycle))) - cycle
    }
}

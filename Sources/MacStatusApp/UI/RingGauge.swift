import SwiftUI

public enum RingMath {
    public static func trimFraction(percentage: Double) -> Double {
        let clamped = max(0.0, min(100.0, percentage))
        return clamped / 100.0
    }
}

public struct RingGauge: View {
    public let percentage: Double
    public let tintColor: Color
    public let size: CGFloat
    public let lineWidth: CGFloat

    public init(
        percentage: Double,
        tintColor: Color,
        size: CGFloat = 11,
        lineWidth: CGFloat = 2.0
    ) {
        self.percentage = percentage
        self.tintColor = tintColor
        self.size = size
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            // Background Track
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: lineWidth)

            // Progress Arc
            Circle()
                .trim(from: 0.0, to: CGFloat(RingMath.trimFraction(percentage: percentage)))
                .stroke(
                    tintColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

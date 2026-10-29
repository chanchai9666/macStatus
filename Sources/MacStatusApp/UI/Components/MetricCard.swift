import SwiftUI

public struct MetricCard<Content: View>: View {
    public let title: String
    public let badge: String
    public let progress: Double?
    public let progressColor: Color
    public let content: Content?

    public init(
        title: String,
        badge: String,
        progress: Double? = nil,
        progressColor: Color = .blue,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.badge = badge
        self.progress = progress
        self.progressColor = progressColor
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(white: 0.65))
                Spacer()
                Text(badge)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }

            if let progress = progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 5)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(progressColor)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(progress))), height: 5)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 5)
            }

            if let content = content {
                content
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.12).opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

extension MetricCard where Content == EmptyView {
    public init(
        title: String,
        badge: String,
        progress: Double? = nil,
        progressColor: Color = .blue
    ) {
        self.title = title
        self.badge = badge
        self.progress = progress
        self.progressColor = progressColor
        self.content = nil
    }
}

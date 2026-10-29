import SwiftUI

public struct ProcessListView: View {
    public let title: String
    public let processes: [TopProcessItem]
    public let isMemory: Bool

    public init(title: String = "Top Processes:", processes: [TopProcessItem], isMemory: Bool = false) {
        self.title = title
        self.processes = processes
        self.isMemory = isMemory
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundColor(Color(white: 0.55))
                .padding(.top, 2)

            if processes.isEmpty {
                Text("Sampling...")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(white: 0.4))
            } else {
                ForEach(processes) { item in
                    HStack {
                        Text(item.name)
                            .font(.system(size: 10.5))
                            .lineLimit(1)
                            .foregroundColor(Color(white: 0.85))
                        Spacer()
                        Text(isMemory ? item.formattedMemory : item.formattedCPU)
                            .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

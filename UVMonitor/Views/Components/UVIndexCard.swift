import SwiftUI

struct UVIndexCard: View {
    let uvIndex: Double
    let level: UVLevel
    let lastUpdated: Date?

    var body: some View {
        VStack(spacing: 8) {
            Text("UV Index")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Text(String(format: "%.1f", uvIndex))
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(level.rawValue.uppercased())
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            if let lastUpdated {
                Text("Updated \(lastUpdated, style: .time)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(level.color.gradient)
        )
    }
}

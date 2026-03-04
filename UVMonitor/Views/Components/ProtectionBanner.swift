import SwiftUI

struct ProtectionBanner: View {
    let level: UVLevel
    let protectionStart: Date?
    let protectionEnd: Date?

    var body: some View {
        if level.needsProtection {
            VStack(alignment: .leading, spacing: 4) {
                Label("Sun Protection Required", systemImage: "sun.max.trianglebadge.exclamationmark.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(level.protectionAdvice)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let start = protectionStart, let end = protectionEnd {
                    Text("Protect \(start, style: .time) – \(end, style: .time)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.orange.opacity(0.1))
                    .strokeBorder(.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

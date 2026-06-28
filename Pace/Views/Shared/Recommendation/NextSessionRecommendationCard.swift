import SwiftUI

struct NextSessionRecommendationCard: View {
    let recommendation: NextSessionRecommendation
    let onStartFocus: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Next")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(recommendation.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                }

                Text(recommendation.reasonText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 8)

            if recommendation.canStartFocusTimer {
                Button(action: onStartFocus) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.primary))
                        .foregroundStyle(Color(nsColor: .controlBackgroundColor))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start focus")
                .help("Start focus")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.58))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var iconName: String {
        switch recommendation.sessionType {
        case .focus:
            return "target"
        case .shortReset:
            return "arrow.counterclockwise"
        case .wrapUp:
            return "checkmark.circle"
        }
    }

    private var iconColor: Color {
        switch recommendation.sessionType {
        case .focus:
            return .red
        case .shortReset:
            return .green
        case .wrapUp:
            return .blue
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        NextSessionRecommendationCard(
            recommendation: NextSessionRecommendation(
                sessionType: .focus,
                reason: .enoughTimeBeforeEvent(minutesUntilEvent: 45)
            ),
            onStartFocus: {}
        )

        NextSessionRecommendationCard(
            recommendation: NextSessionRecommendation(
                sessionType: .wrapUp,
                reason: .endOfDay
            ),
            onStartFocus: {}
        )
    }
    .padding()
    .frame(width: 360)
}

import SwiftUI

struct ResultPopupView: View {
    let execution: PromptExecution
    let onViewHistory: () -> Void

    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: execution.timestamp)
    }

    private var statusIcon: String {
        execution.wasActionable ? "exclamationmark.circle.fill" : "checkmark.circle.fill"
    }

    private var statusText: String {
        execution.wasActionable ? "Action Required" : "No Action Needed"
    }

    private var gradientColors: [Color] {
        let nearBlack = Color(red: 0.102, green: 0.102, blue: 0.110) // #1a1a1c
        if execution.wasActionable {
            let darkGreen = Color(red: 0.290, green: 0.522, blue: 0.376) // #4a8560
            return [darkGreen, nearBlack]
        } else {
            let primaryGreen = Color(red: 0.373, green: 0.620, blue: 0.447) // #5f9e72
            return [primaryGreen, nearBlack]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Gradient header with prompt name and timestamp chip
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: statusIcon)
                        .font(.system(size: 16))
                    Text(statusText)
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text(formattedTimestamp)
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
                .foregroundColor(.white)

                HStack {
                    Text(execution.promptName)
                        .font(.system(size: 18, weight: .bold))
                        .lineLimit(1)
                    Spacer()
                    Text("\(execution.emailCount) email\(execution.emailCount == 1 ? "" : "s") analysed")
                        .font(.system(size: 12))
                        .opacity(0.85)
                }
                .foregroundColor(.white)
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Scrollable result content with markdown rendering
            ScrollView {
                MarkdownTextView(markdown: execution.result, baseFontSize: 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
            }

            Divider()

            // Footer with action buttons
            HStack(spacing: 12) {
                Button(action: {
                    NSApp.keyWindow?.close()
                }) {
                    Text("Dismiss")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(action: onViewHistory) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("View History")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(20)
        }
        .frame(minWidth: 400, minHeight: 400)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}


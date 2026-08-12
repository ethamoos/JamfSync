//
//  Copyright 2024, Jamf
//

import SwiftUI

/// A debug panel that displays recent network/connection/sync error and warning messages
/// on the main screen. Intended to help users diagnose connection and synchronization problems.
struct DebugPanelView: View {
    @StateObject var logViewModel = LogViewModel()

    private var debugMessages: [LogMessage] {
        logViewModel.logMessages.filter { $0.showInDebugPanel() }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "ladybug")
                Text("Debug: Network & Error Messages")
                    .font(.headline)
                Spacer()
                Button {
                    logViewModel.clear()
                } label: {
                    Image(systemName: "trash")
                }
                .help("Clear debug messages")
                .buttonStyle(.borderless)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        if debugMessages.isEmpty {
                            Text("No network or error messages logged yet.")
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.vertical, 2)
                        } else {
                            ForEach(debugMessages) { logMessage in
                                HStack(alignment: .top, spacing: 8) {
                                    Text(LogManager.shared.dateToLogDateString(logMessage.date))
                                        .foregroundColor(.secondary)
                                        .frame(width: 130, alignment: .leading)
                                    Text(logMessage.logLevel.rawValue)
                                        .foregroundColor(logLevelColor(logLevel: logMessage.logLevel))
                                        .frame(width: 70, alignment: .leading)
                                    Text(logMessage.message)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .font(.system(.caption, design: .monospaced))
                                .id(logMessage.id)
                            }
                        }
                    }
                    .padding(6)
                }
                .onChange(of: debugMessages.count) {
                    if let last = debugMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .frame(height: 120)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
            )
        }
        .padding([.leading, .trailing, .bottom])
    }

    func logLevelColor(logLevel: LogLevel) -> Color {
        switch logLevel {
        case .error:
            return .red
        case .warning:
            return .orange
        case .info:
            return .green
        default:
            return .gray
        }
    }
}

struct DebugPanelView_Previews: PreviewProvider {
    static var previews: some View {
        DebugPanelView()
    }
}

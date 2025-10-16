//
//  Copyright 2024, Jamf
//

import Foundation

class LogViewModel {
    static let messageDuration = 5.0
#if !JAMF_SYNC_CLI
    @Published
#endif
    var logMessages: [LogMessage] = []
#if !JAMF_SYNC_CLI
    @Published
#endif
    var messageToShow: LogMessage?
    var observer: NSObjectProtocol?
    var timer: Timer?

    init() {
        copyMessagesFromLogManager()
        observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(LogManager.logMessageNotification), object: nil, queue: .main, using: { [weak self] notification in
            if let logMessage = notification.object as? LogMessage {
                self?.messageAdded(logMessage: logMessage)
            }
        })
    }

    deinit {
        stopNotifications()
    }

    func clear() {
        logMessages.removeAll()
    }

    func findLogMessage(id: UUID) -> LogMessage? {
        return logMessages.first { $0.id == id }
    }

    // MARK: - Private functions

    private func stopNotifications() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }

    private func copyMessagesFromLogManager() {
        for logMessage in LogManager.shared.logMessages {
            logMessages.append(logMessage)
        }
    }

    private func messageAdded(logMessage: LogMessage) {
        Task { @MainActor in
            logMessages.append(logMessage)
            if logMessage.showOnMainScreen() {
                messageToShow = logMessage
                if let timer {
                    timer.invalidate()
                    self.timer = nil
                }
                timer = Timer.scheduledTimer(withTimeInterval: Self.messageDuration, repeats: false, block: { timer in
                    self.messageToShow = nil
                })
            }
        }
    }
}

#if !JAMF_SYNC_CLI
extension LogViewModel: ObservableObject {}
#endif

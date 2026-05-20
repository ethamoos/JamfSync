import Foundation

struct LogMessage: Identifiable {
    let id = UUID()
    let date = Date()
    let message: String
}

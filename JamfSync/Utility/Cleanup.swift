//
//  Cleanup.swift
//  Jamf Sync
//
//  Created by Harry Strand on 10/10/25.
//

import Foundation

class Cleanup {
    static let cleanupTimeout = 10.0

   /// Performs any cleanup necessary before ending the program.
    ///   - Returns: Returns true if it succeed or false if it timed out.
    static func waitForCleanup() -> Bool {
        DataModel.shared.cancelUpdateListViewModels()
        let group = DispatchGroup()
        group.enter()
        Task {
            do {
                try await DataModel.shared.cleanup()
            } catch {
                LogManager.shared.logMessage(message: "Failed to cleanup the distribution points: \(error)", level: .error)
            }
            group.leave()
        }
        if group.wait(timeout: DispatchTime.now() + Self.cleanupTimeout) != .success {
            return false
        }
        return true
    }
}

//
//  Copyright 2024, Jamf
//

import Foundation

class SettingsViewModel {
    let userSettings = UserSettings()

#if !JAMF_SYNC_CLI
    @Published
#endif
    var allowDeletionsAfterSynchronization: DeletionOptions = .none
#if !JAMF_SYNC_CLI
    @Published
#endif
    var allowManualDeletions: DeletionOptions = .filesAndAssociatedPackages
#if !JAMF_SYNC_CLI
    @Published
#endif
    var promptForJamfProInstances = false

    init() {
        loadSettings()
    }

    func loadSettings() {
        allowDeletionsAfterSynchronization = userSettings.allowDeletionsAfterSynchronization
        allowManualDeletions = userSettings.allowManualDeletions
        promptForJamfProInstances = userSettings.promptForJamfProInstances
    }

    func saveSettings() {
        userSettings.allowDeletionsAfterSynchronization = allowDeletionsAfterSynchronization
        userSettings.allowManualDeletions = allowManualDeletions
        userSettings.promptForJamfProInstances = promptForJamfProInstances
    }
}

#if !JAMF_SYNC_CLI
extension SettingsViewModel: ObservableObject {}
#endif

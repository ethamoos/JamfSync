//
//  Copyright 2024, Jamf
//

import Foundation

class SettingsViewModel: ObservableObject {
    let userSettings = UserSettings()

    @Published var allowDeletionsAfterSynchronization: DeletionOptions = .none
    @Published var allowManualDeletions: DeletionOptions = .filesAndAssociatedPackages
    @Published var promptForJamfProInstances = false
    @Published var hideSrcSizeColumn: Bool = false
    @Published var hideSrcChecksumColumn: Bool = false
    @Published var hideDstSizeColumn: Bool = false
    @Published var hideDstChecksumColumn: Bool = false

    init() {
        loadSettings()
    }

    func loadSettings() {
        allowDeletionsAfterSynchronization = userSettings.allowDeletionsAfterSynchronization
        allowManualDeletions = userSettings.allowManualDeletions
        promptForJamfProInstances = userSettings.promptForJamfProInstances
        hideSrcSizeColumn = userSettings.hideSrcSizeColumn
        hideSrcChecksumColumn = userSettings.hideSrcChecksumColumn
        hideDstSizeColumn = userSettings.hideDstSizeColumn
        hideDstChecksumColumn = userSettings.hideDstChecksumColumn
    }

    func saveSettings() {
        userSettings.allowDeletionsAfterSynchronization = allowDeletionsAfterSynchronization
        userSettings.allowManualDeletions = allowManualDeletions
        userSettings.promptForJamfProInstances = promptForJamfProInstances
        userSettings.hideSrcSizeColumn = hideSrcSizeColumn
        userSettings.hideSrcChecksumColumn = hideSrcChecksumColumn
        userSettings.hideDstSizeColumn = hideDstSizeColumn
        userSettings.hideDstChecksumColumn = hideDstChecksumColumn
    }
}

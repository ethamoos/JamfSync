//
//  Copyright 2024, Jamf
//

import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if DataModel.shared.synchronizationInProgress {
            let alert = NSAlert()
            alert.messageText = "Are you sure you want to quit JamfSync?"
            alert.informativeText = "Closing while a synchronization is in progress will abort the synchroniztion process."
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .warning
            let result = alert.runModal().rawValue // For some reason, comparing against .OK or .cancel didn't work
            if result == 1001 {
                return .terminateCancel
            }
        }
        if !Cleanup.waitForCleanup() {
            let alert = NSAlert()
            alert.messageText = "Unmounting distribution points may have failed."
            alert.informativeText = "This may be because a distribution point was unmounted externally. Otherwise you may need to unmount these manually using Finder or locate the volume name in /Volumes and run \"diskutil unmount /Volumes/name\" from terminal."
            alert.addButton(withTitle: "OK")
            alert.alertStyle = .warning
            alert.runModal()
        }
        return .terminateNow
    }
}

@main
struct JamfSyncApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var dataPersistence = DataPersistence(dataManager: DataManager())

    var body: some Scene {
        WindowGroup {
            startingView()
        }
        .commands {
            CommandGroup(replacing: .help) {
                HelpMenu()
            }
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button(action: {
                    AboutView().openInNewWindow { window in
                        window.title = "About Jamf Sync"
                    }
                }) {
                    Text("About Jamf Sync")
                }
            }
        }
        Settings {
            SettingsView(settingsViewModel: DataModel.shared.settingsViewModel)
        }
    }

    func startingView() -> some View {
        let argumentParser = ArgumentParser(arguments: CommandLine.arguments)
        if !argumentParser.processArgs() {
            exit(1)
        }

        if argumentParser.someArgumentsPassed {
            let commandLineProcessing = CommandLineProcessing(dataModel: DataModel.shared, dataPersistence: dataPersistence)
            let succeeded = commandLineProcessing.process(argumentParser: argumentParser)
            _ = Cleanup.waitForCleanup()
            if succeeded {
                exit(0)
            } else {
                exit(1)
            }
        } else {
            return ContentView(dataPersistence: dataPersistence)
                .environmentObject(dataPersistence.dataManager)
                .environment(\.managedObjectContext, dataPersistence.dataManager.container.viewContext)
        }
    }
}

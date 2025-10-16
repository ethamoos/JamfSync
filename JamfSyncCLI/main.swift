//
//  main.swift
//  JamfSyncCLI
//
//  Created by Harry Strand on 10/7/25.
//

import Foundation

let argumentParser = ArgumentParser(arguments: CommandLine.arguments)
if !argumentParser.processArgs() {
    exit(1)
}

if argumentParser.someArgumentsPassed {
    var dataPersistence = DataPersistence(dataManager: DataManager())
    let commandLineProcessing = CommandLineProcessing(dataModel: DataModel.shared, dataPersistence: dataPersistence)
    let succeeded = commandLineProcessing.process(argumentParser: argumentParser)
    if !Cleanup.waitForCleanup() {
        LogManager.shared.logMessage(message: "Unmounting distribution points may have failed. This may be because a distribution point was unmounted externally. Otherwise you may need to unmount these manually using Finder or locate the volume name in /Volumes and run \"diskutil unmount /Volumes/name\" from terminal.", level: .error)
    }
    if !succeeded {
        exit(1)
    }
} else {
    argumentParser.displayHelp()
}

exit(0)

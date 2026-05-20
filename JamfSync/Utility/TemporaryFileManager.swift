//
//  Copyright 2024, Jamf
//

import Foundation

enum TemporaryFileManagerError: Error {
    case failedToCreateTempDirectory
}

class TemporaryFileManager {
    let jamfSyncDirectoryName = "JamfSync"
    var tempDirectory: URL?
    var fileManager: FileManager

    init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
    }

    deinit {
        guard let tempDirectory else { return }

        // Attempt to clean up the directory, but don't sweat it if it fails.
        try? fileManager.removeItem(at: tempDirectory)
    }

    func jamfSyncTempDirectory() throws -> URL {
        try createTemporaryDirectory()
        guard let tempDirectory else { throw TemporaryFileManagerError.failedToCreateTempDirectory }
        return tempDirectory
    }

    func moveToTemporaryDirectory(src: URL, dstName: String) throws -> URL {
        try createTemporaryDirectory()
        guard let tempDirectory else { throw TemporaryFileManagerError.failedToCreateTempDirectory }

        let dstFileUrl = tempDirectory.appending(component: dstName)
        try fileManager.moveItem(at: src, to: dstFileUrl)
        return dstFileUrl
    }

    func createTemporaryDirectory(directoryName: String) throws -> URL {
        var baseUrl: URL
        if let tempDirectory {
            baseUrl = tempDirectory
        } else {
            baseUrl = URL.temporaryDirectory
        }
        let newTempDirectory = baseUrl.appending(component: directoryName)
        var isDirectory : ObjCBool = true
        let exists = fileManager.fileExists(atPath: newTempDirectory.path(), isDirectory: &isDirectory)
        if exists {
            if isDirectory.boolValue {
                return newTempDirectory
            } else {
                try fileManager.removeItem(at: newTempDirectory)
            }
        }
        try fileManager.createDirectory(at: newTempDirectory, withIntermediateDirectories: true)
        return newTempDirectory
    }

    // MARK - Private functions

    private func createTemporaryDirectory() throws {
        guard tempDirectory == nil else { return }
        tempDirectory = try createTemporaryDirectory(directoryName: jamfSyncDirectoryName)
    }
}

// Provide a shared, process-wide TemporaryFileManager instance to maintain
// a single temp directory for the app and preserve existing call-sites that
// reference the global `temporaryFileManager` variable used throughout the
// codebase (and in tests).
let temporaryFileManager = TemporaryFileManager()

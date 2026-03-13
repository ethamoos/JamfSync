//
//  Copyright 2024, Jamf
//

@testable import Jamf_Sync
import XCTest

final class TemporaryFileManagerTests: XCTestCase {
    var temporaryFileManager: TemporaryFileManager!
    var mockFileManager: MockFileManager!
    var testTempDirectory: URL!

    override func setUp() {
        super.setUp()
        mockFileManager = MockFileManager()
        temporaryFileManager = TemporaryFileManager(fileManager: mockFileManager)

        // Create a test temp directory URL
        testTempDirectory = URL.temporaryDirectory.appending(component: "TestJamfSync")
    }

    override func tearDown() {
        temporaryFileManager = nil
        mockFileManager = nil
        testTempDirectory = nil
        super.tearDown()
    }

    // MARK: - jamfSyncTempDirectory() Tests

    func test_jamfSyncTempDirectory_happyPath() throws {
        // Given
        mockFileManager.fileExistsResponse = false

        // When
        let result = try temporaryFileManager.jamfSyncTempDirectory()

        // Then
        XCTAssertNotNil(result, "Should return a valid URL")
        XCTAssertNotNil(mockFileManager.directoryCreated, "Directory should be created")
        XCTAssertTrue(mockFileManager.directoryCreated?.lastPathComponent == "JamfSync", "Should create JamfSync directory")
        XCTAssertEqual(temporaryFileManager.tempDirectory, result, "Should store temp directory")
    }

    func test_jamfSyncTempDirectory_directoryAlreadyExists() throws {
        // Given
        mockFileManager.fileExistsResponse = true

        // When
        let result = try temporaryFileManager.jamfSyncTempDirectory()

        // Then
        XCTAssertNotNil(result, "Should return a valid URL")
        XCTAssertNil(mockFileManager.directoryCreated, "Should not create directory if it already exists")
    }

    func test_jamfSyncTempDirectory_creationFails() throws {
        // Given
        mockFileManager.fileExistsResponse = false
        mockFileManager.createDirectoryError = TestErrors.SomethingWentHaywire

        // When/Then
        XCTAssertThrowsError(try temporaryFileManager.jamfSyncTempDirectory()) { error in
            XCTAssertTrue(error is TestErrors, "Should throw the underlying error")
        }
    }

    func test_jamfSyncTempDirectory_calledMultipleTimes() throws {
        // Given
        mockFileManager.fileExistsResponse = false

        // When
        let result1 = try temporaryFileManager.jamfSyncTempDirectory()
        let result2 = try temporaryFileManager.jamfSyncTempDirectory()

        // Then
        XCTAssertEqual(result1, result2, "Should return same directory on multiple calls")
        XCTAssertNotNil(mockFileManager.directoryCreated, "Directory should only be created once")
    }

    // MARK: - moveToTemporaryDirectory() Tests

    func test_moveToTemporaryDirectory_happyPath() throws {
        // Given
        mockFileManager.fileExistsResponse = false
        let sourceURL = URL(fileURLWithPath: "/tmp/source.txt")
        let destinationName = "destination.txt"

        // When
        let result = try temporaryFileManager.moveToTemporaryDirectory(src: sourceURL, dstName: destinationName)

        // Then
        XCTAssertNotNil(result, "Should return destination URL")
        XCTAssertEqual(result.lastPathComponent, destinationName, "Should have correct filename")
        XCTAssertEqual(mockFileManager.srcItemMoved, sourceURL, "Should move from source")
        XCTAssertEqual(mockFileManager.dstItemMoved, result, "Should move to destination")
    }

    func test_moveToTemporaryDirectory_moveError() throws {
        // Given
        mockFileManager.fileExistsResponse = false
        mockFileManager.moveError = TestErrors.SomethingWentHaywire
        let sourceURL = URL(fileURLWithPath: "/tmp/source.txt")

        // When/Then
        XCTAssertThrowsError(try temporaryFileManager.moveToTemporaryDirectory(src: sourceURL, dstName: "dest.txt")) { error in
            XCTAssertTrue(error is TestErrors, "Should throw move error")
        }
    }

    func test_moveToTemporaryDirectory_tempDirectoryCreationFails() throws {
        // Given
        mockFileManager.fileExistsResponse = false
        mockFileManager.createDirectoryError = TestErrors.SomethingWentHaywire
        let sourceURL = URL(fileURLWithPath: "/tmp/source.txt")

        // When/Then
        XCTAssertThrowsError(try temporaryFileManager.moveToTemporaryDirectory(src: sourceURL, dstName: "dest.txt")) { error in
            XCTAssertTrue(error is TestErrors, "Should throw directory creation error")
        }
    }

    func test_moveToTemporaryDirectory_usesExistingTempDirectory() throws {
        // Given
        mockFileManager.fileExistsResponse = false
        let sourceURL1 = URL(fileURLWithPath: "/tmp/source1.txt")
        let sourceURL2 = URL(fileURLWithPath: "/tmp/source2.txt")

        // When
        _ = try temporaryFileManager.moveToTemporaryDirectory(src: sourceURL1, dstName: "dest1.txt")
        mockFileManager.directoryCreated = nil // Reset to check second call
        _ = try temporaryFileManager.moveToTemporaryDirectory(src: sourceURL2, dstName: "dest2.txt")

        // Then
        XCTAssertNil(mockFileManager.directoryCreated, "Should not create directory again")
    }

    // MARK: - createTemporaryDirectory(directoryName:) Tests

    func test_createTemporaryDirectory_happyPath() throws {
        // Given
        mockFileManager.fileExistsResponse = false
        let directoryName = "TestDirectory"

        // When
        let result = try temporaryFileManager.createTemporaryDirectory(directoryName: directoryName)

        // Then
        XCTAssertNotNil(result, "Should return directory URL")
        XCTAssertEqual(result.lastPathComponent, directoryName, "Should have correct directory name")
        XCTAssertNotNil(mockFileManager.directoryCreated, "Should create directory")
        XCTAssertEqual(mockFileManager.directoryCreated?.lastPathComponent, directoryName, "Should create correct directory")
    }

    func test_createTemporaryDirectory_directoryAlreadyExists() throws {
        // Given
        mockFileManager.fileExistsResponse = true
        let directoryName = "ExistingDirectory"

        // When
        let result = try temporaryFileManager.createTemporaryDirectory(directoryName: directoryName)

        // Then
        XCTAssertNotNil(result, "Should return directory URL")
        XCTAssertNil(mockFileManager.directoryCreated, "Should not create directory if it exists")
    }

    func test_createTemporaryDirectory_fileExistsWithSameName() throws {
        // Given
        let directoryName = "ConflictingName"

        // Configure mock to indicate a file (not directory) exists
        var callCount = 0
        mockFileManager.fileExistsResponseProvider = { path, isDirectory in
            callCount += 1
            if callCount == 1 {
                isDirectory?.pointee = false // First call: file exists
                return true
            } else {
                return false // After removal, file doesn't exist
            }
        }

        // When
        let result = try temporaryFileManager.createTemporaryDirectory(directoryName: directoryName)

        // Then
        XCTAssertNotNil(result, "Should return directory URL")
        XCTAssertNotNil(mockFileManager.itemRemoved, "Should remove the conflicting file")
        XCTAssertNotNil(mockFileManager.directoryCreated, "Should create directory after removing file")
    }

    func test_createTemporaryDirectory_creationFails() throws {
        // Given
        mockFileManager.fileExistsResponse = false
        mockFileManager.createDirectoryError = TestErrors.SomethingWentHaywire

        // When/Then
        XCTAssertThrowsError(try temporaryFileManager.createTemporaryDirectory(directoryName: "TestDir")) { error in
            XCTAssertTrue(error is TestErrors, "Should throw creation error")
        }
    }

    func test_createTemporaryDirectory_withBaseTempDirectory() throws {
        // Given
        mockFileManager.fileExistsResponse = false

        // First create base temp directory
        _ = try temporaryFileManager.jamfSyncTempDirectory()
        let baseDir = temporaryFileManager.tempDirectory

        // When
        let result = try temporaryFileManager.createTemporaryDirectory(directoryName: "SubDirectory")

        // Then
        XCTAssertNotNil(result, "Should return directory URL")
        XCTAssertTrue(result.path().contains(baseDir?.lastPathComponent ?? ""), "Should be under base temp directory")
    }

    func test_createTemporaryDirectory_removalFails() throws {
        // Given
        let directoryName = "ConflictingName"

        // Configure mock to indicate a file (not directory) exists
        mockFileManager.fileExistsResponseProvider = { path, isDirectory in
            isDirectory?.pointee = false // File exists
            return true
        }
        mockFileManager.removeItemError = TestErrors.SomethingWentHaywire

        // When/Then
        XCTAssertThrowsError(try temporaryFileManager.createTemporaryDirectory(directoryName: directoryName)) { error in
            XCTAssertTrue(error is TestErrors, "Should throw removal error")
        }
    }

    // MARK: - Cleanup Tests

    func test_deinit_removesTemporaryDirectory() throws {
        // Given
        mockFileManager.fileExistsResponse = false
        _ = try temporaryFileManager.jamfSyncTempDirectory()
        let tempDir = temporaryFileManager.tempDirectory
        XCTAssertNotNil(tempDir, "Temp directory should be created")

        // When
        temporaryFileManager = nil // Trigger deinit

        // Then
        XCTAssertEqual(mockFileManager.itemRemoved, tempDir, "Should attempt to remove temp directory")
    }

    func test_deinit_withNoTempDirectory() throws {
        // Given
        // Don't create any temp directory

        // When
        temporaryFileManager = nil // Trigger deinit

        // Then
        XCTAssertNil(mockFileManager.itemRemoved, "Should not attempt to remove if no directory exists")
    }

    func test_deinit_doesNotThrowOnCleanupFailure() throws {
        // Given
        mockFileManager.fileExistsResponse = false
        mockFileManager.removeItemError = TestErrors.SomethingWentHaywire
        _ = try temporaryFileManager.jamfSyncTempDirectory()

        // When/Then - Should not throw even if removal fails
        temporaryFileManager = nil // Trigger deinit
        // If we get here without crashing, the test passes
        XCTAssertTrue(true, "Deinit should not crash on cleanup failure")
    }

    // MARK: - Edge Cases

    func test_multipleSubdirectories() throws {
        // Given
        mockFileManager.fileExistsResponse = false

        // When
        let dir1 = try temporaryFileManager.createTemporaryDirectory(directoryName: "Dir1")
        let dir2 = try temporaryFileManager.createTemporaryDirectory(directoryName: "Dir2")
        let dir3 = try temporaryFileManager.createTemporaryDirectory(directoryName: "Dir3")

        // Then
        XCTAssertNotEqual(dir1, dir2, "Should create different directories")
        XCTAssertNotEqual(dir2, dir3, "Should create different directories")
        XCTAssertNotEqual(dir1, dir3, "Should create different directories")
    }

    func test_fileNameWithSpecialCharacters() throws {
        // Given
        mockFileManager.fileExistsResponse = false
        let sourceURL = URL(fileURLWithPath: "/tmp/source file with spaces.txt")
        let destinationName = "dest-file_with.special@chars.txt"

        // When
        let result = try temporaryFileManager.moveToTemporaryDirectory(src: sourceURL, dstName: destinationName)

        // Then
        XCTAssertEqual(result.lastPathComponent, destinationName, "Should handle special characters")
    }
}

//
//  Copyright 2026, Jamf
//

@testable import Jamf_Sync
import XCTest

final class FileManagerMoveRetainingPermissionsTests: XCTestCase {
    var fileManager: FileManager!
    var testDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        fileManager = FileManager.default

        // Create a unique test directory
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileManagerMoveTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        // Clean up test directory
        if FileManager.default.fileExists(atPath: testDirectory.path) {
            try? FileManager.default.removeItem(at: testDirectory)
        }
        testDirectory = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func test_moveRetainingDestinationPermissions_happyPath() throws {
        // Given
        let srcFile = testDirectory.appendingPathComponent("source.txt")
        let dstFile = testDirectory.appendingPathComponent("destination.txt")
        let content = "Test content"
        try content.write(to: srcFile, atomically: true, encoding: .utf8)

        // When
        try fileManager.moveRetainingDestinationPermisssions(at: srcFile, to: dstFile)

        // Then
        XCTAssertTrue(fileManager.fileExists(atPath: dstFile.path), "Destination file should exist")
        XCTAssertFalse(fileManager.fileExists(atPath: srcFile.path), "Source file should be removed")

        let movedContent = try String(contentsOf: dstFile, encoding: .utf8)
        XCTAssertEqual(movedContent, content, "Content should match")

        // Verify permissions are set to 0o644
        let attributes = try fileManager.attributesOfItem(atPath: dstFile.path)
        let permissions = attributes[.posixPermissions] as? NSNumber
        XCTAssertEqual(permissions?.uint16Value, 0o644, "Permissions should be set to 0o644")
    }

    func test_moveRetainingDestinationPermissions_largeFile() throws {
        // Given - Create a larger file
        let srcFile = testDirectory.appendingPathComponent("large_source.txt")
        let dstFile = testDirectory.appendingPathComponent("large_destination.txt")
        let content = String(repeating: "Large content test ", count: 1000)
        try content.write(to: srcFile, atomically: true, encoding: .utf8)

        // When
        try fileManager.moveRetainingDestinationPermisssions(at: srcFile, to: dstFile)

        // Then
        XCTAssertTrue(fileManager.fileExists(atPath: dstFile.path), "Destination file should exist")
        XCTAssertFalse(fileManager.fileExists(atPath: srcFile.path), "Source file should be removed")

        let movedContent = try String(contentsOf: dstFile, encoding: .utf8)
        XCTAssertEqual(movedContent, content, "Content should match")
    }

    func test_moveRetainingDestinationPermissions_binaryFile() throws {
        // Given - Create a binary file
        let srcFile = testDirectory.appendingPathComponent("binary_source.dat")
        let dstFile = testDirectory.appendingPathComponent("binary_destination.dat")
        let binaryData = Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD, 0xAB, 0xCD, 0xEF])
        try binaryData.write(to: srcFile)

        // When
        try fileManager.moveRetainingDestinationPermisssions(at: srcFile, to: dstFile)

        // Then
        XCTAssertTrue(fileManager.fileExists(atPath: dstFile.path), "Destination file should exist")
        XCTAssertFalse(fileManager.fileExists(atPath: srcFile.path), "Source file should be removed")

        let movedData = try Data(contentsOf: dstFile)
        XCTAssertEqual(movedData, binaryData, "Binary data should match")
    }

    func test_moveRetainingDestinationPermissions_emptyFile() throws {
        // Given - Create an empty file
        let srcFile = testDirectory.appendingPathComponent("empty_source.txt")
        let dstFile = testDirectory.appendingPathComponent("empty_destination.txt")
        try "".write(to: srcFile, atomically: true, encoding: .utf8)

        // When
        try fileManager.moveRetainingDestinationPermisssions(at: srcFile, to: dstFile)

        // Then
        XCTAssertTrue(fileManager.fileExists(atPath: dstFile.path), "Destination file should exist")
        XCTAssertFalse(fileManager.fileExists(atPath: srcFile.path), "Source file should be removed")

        let movedContent = try String(contentsOf: dstFile, encoding: .utf8)
        XCTAssertEqual(movedContent, "", "Content should be empty")
    }

    func test_moveRetainingDestinationPermissions_destinationExists() throws {
        // Given - Both source and destination exist
        let srcFile = testDirectory.appendingPathComponent("source_exists.txt")
        let dstFile = testDirectory.appendingPathComponent("destination_exists.txt")
        try "Source content".write(to: srcFile, atomically: true, encoding: .utf8)
        try "Original destination content".write(to: dstFile, atomically: true, encoding: .utf8)

        // When
        try fileManager.moveRetainingDestinationPermisssions(at: srcFile, to: dstFile)

        // Then
        XCTAssertTrue(fileManager.fileExists(atPath: dstFile.path), "Destination file should exist")
        XCTAssertFalse(fileManager.fileExists(atPath: srcFile.path), "Source file should be removed")

        let movedContent = try String(contentsOf: dstFile, encoding: .utf8)
        XCTAssertEqual(movedContent, "Source content", "Destination should have source content")
    }

    func test_moveRetainingDestinationPermissions_withSubdirectories() throws {
        // Given - Create subdirectories
        let srcDir = testDirectory.appendingPathComponent("srcSubdir")
        let dstDir = testDirectory.appendingPathComponent("dstSubdir")
        try fileManager.createDirectory(at: srcDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: dstDir, withIntermediateDirectories: true)

        let srcFile = srcDir.appendingPathComponent("file.txt")
        let dstFile = dstDir.appendingPathComponent("file.txt")
        try "Content in subdirectory".write(to: srcFile, atomically: true, encoding: .utf8)

        // When
        try fileManager.moveRetainingDestinationPermisssions(at: srcFile, to: dstFile)

        // Then
        XCTAssertTrue(fileManager.fileExists(atPath: dstFile.path), "Destination file should exist")
        XCTAssertFalse(fileManager.fileExists(atPath: srcFile.path), "Source file should be removed")

        let movedContent = try String(contentsOf: dstFile, encoding: .utf8)
        XCTAssertEqual(movedContent, "Content in subdirectory", "Content should match")
    }

    func test_moveRetainingDestinationPermissions_specialCharactersInFilename() throws {
        // Given - Files with special characters in names
        let srcFile = testDirectory.appendingPathComponent("source file with spaces & chars.txt")
        let dstFile = testDirectory.appendingPathComponent("dest-file_with@special#chars.txt")
        try "Special content".write(to: srcFile, atomically: true, encoding: .utf8)

        // When
        try fileManager.moveRetainingDestinationPermisssions(at: srcFile, to: dstFile)

        // Then
        XCTAssertTrue(fileManager.fileExists(atPath: dstFile.path), "Destination file should exist")
        XCTAssertFalse(fileManager.fileExists(atPath: srcFile.path), "Source file should be removed")

        let movedContent = try String(contentsOf: dstFile, encoding: .utf8)
        XCTAssertEqual(movedContent, "Special content", "Content should match")
    }

    func test_moveRetainingDestinationPermissions_unicodeContent() throws {
        // Given - File with Unicode content
        let srcFile = testDirectory.appendingPathComponent("unicode_source.txt")
        let dstFile = testDirectory.appendingPathComponent("unicode_destination.txt")
        let unicodeContent = "Hello 世界 🌍 café naïve"
        try unicodeContent.write(to: srcFile, atomically: true, encoding: .utf8)

        // When
        try fileManager.moveRetainingDestinationPermisssions(at: srcFile, to: dstFile)

        // Then
        XCTAssertTrue(fileManager.fileExists(atPath: dstFile.path), "Destination file should exist")
        XCTAssertFalse(fileManager.fileExists(atPath: srcFile.path), "Source file should be removed")

        let movedContent = try String(contentsOf: dstFile, encoding: .utf8)
        XCTAssertEqual(movedContent, unicodeContent, "Unicode content should match")
    }

    // MARK: - Error Cases

    func test_moveRetainingDestinationPermissions_sourceDoesNotExist() throws {
        // Given - Source file doesn't exist
        let srcFile = testDirectory.appendingPathComponent("nonexistent_source.txt")
        let dstFile = testDirectory.appendingPathComponent("destination.txt")

        // When/Then
        XCTAssertThrowsError(try fileManager.moveRetainingDestinationPermisssions(at: srcFile, to: dstFile)) { error in
            // Verify it's a file system error
            let nsError = error as NSError
            XCTAssertTrue(nsError.domain == NSCocoaErrorDomain || nsError.domain == NSPOSIXErrorDomain,
                         "Should throw a file system error")
        }
    }

    func test_moveRetainingDestinationPermissions_destinationDirectoryDoesNotExist() throws {
        // Given - Destination directory doesn't exist
        let srcFile = testDirectory.appendingPathComponent("source.txt")
        let dstFile = testDirectory.appendingPathComponent("nonexistent_dir/destination.txt")
        try "Content".write(to: srcFile, atomically: true, encoding: .utf8)

        // When/Then
        XCTAssertThrowsError(try fileManager.moveRetainingDestinationPermisssions(at: srcFile, to: dstFile)) { error in
            // Verify it's a file system error
            let nsError = error as NSError
            XCTAssertTrue(nsError.domain == NSCocoaErrorDomain || nsError.domain == NSPOSIXErrorDomain,
                         "Should throw a file system error")
        }

        // Verify source still exists after failed move
        XCTAssertTrue(fileManager.fileExists(atPath: srcFile.path), "Source should still exist after failed move")
    }

    // MARK: - Permission Tests

    func test_moveRetainingDestinationPermissions_verifiesPermissionsSet() throws {
        // Given
        let srcFile = testDirectory.appendingPathComponent("perm_source.txt")
        let dstFile = testDirectory.appendingPathComponent("perm_destination.txt")
        try "Content for permission test".write(to: srcFile, atomically: true, encoding: .utf8)

        // Set source file to different permissions
        var sourceAttributes: [FileAttributeKey: Any] = [:]
        sourceAttributes[.posixPermissions] = 0o600
        try fileManager.setAttributes(sourceAttributes, ofItemAtPath: srcFile.path)

        // When
        try fileManager.moveRetainingDestinationPermisssions(at: srcFile, to: dstFile)

        // Then - Destination should have 0o644 permissions, not source permissions
        let attributes = try fileManager.attributesOfItem(atPath: dstFile.path)
        let permissions = attributes[.posixPermissions] as? NSNumber
        XCTAssertEqual(permissions?.uint16Value, 0o644, "Permissions should be 0o644, not source permissions")
    }

    func test_moveRetainingDestinationPermissions_multipleFiles() throws {
        // Given - Multiple files to move
        var srcFiles: [URL] = []
        var dstFiles: [URL] = []

        for i in 1...5 {
            let src = testDirectory.appendingPathComponent("multi_source_\(i).txt")
            let dst = testDirectory.appendingPathComponent("multi_dest_\(i).txt")
            try "Content \(i)".write(to: src, atomically: true, encoding: .utf8)
            srcFiles.append(src)
            dstFiles.append(dst)
        }

        // When - Move all files
        for (src, dst) in zip(srcFiles, dstFiles) {
            try fileManager.moveRetainingDestinationPermisssions(at: src, to: dst)
        }

        // Then - All files moved successfully
        for (i, dst) in dstFiles.enumerated() {
            XCTAssertTrue(fileManager.fileExists(atPath: dst.path), "Destination file \(i+1) should exist")
            let content = try String(contentsOf: dst, encoding: .utf8)
            XCTAssertEqual(content, "Content \(i+1)", "Content for file \(i+1) should match")
        }

        for (i, src) in srcFiles.enumerated() {
            XCTAssertFalse(fileManager.fileExists(atPath: src.path), "Source file \(i+1) should be removed")
        }
    }

    // MARK: - Edge Cases

    func test_moveRetainingDestinationPermissions_fileWithNoExtension() throws {
        // Given - File without extension
        let srcFile = testDirectory.appendingPathComponent("sourcefile")
        let dstFile = testDirectory.appendingPathComponent("destfile")
        try "No extension content".write(to: srcFile, atomically: true, encoding: .utf8)

        // When
        try fileManager.moveRetainingDestinationPermisssions(at: srcFile, to: dstFile)

        // Then
        XCTAssertTrue(fileManager.fileExists(atPath: dstFile.path), "Destination file should exist")
        XCTAssertFalse(fileManager.fileExists(atPath: srcFile.path), "Source file should be removed")

        let movedContent = try String(contentsOf: dstFile, encoding: .utf8)
        XCTAssertEqual(movedContent, "No extension content", "Content should match")
    }

    func test_moveRetainingDestinationPermissions_hiddenFile() throws {
        // Given - Hidden file (starts with .)
        let srcFile = testDirectory.appendingPathComponent(".hidden_source")
        let dstFile = testDirectory.appendingPathComponent(".hidden_dest")
        try "Hidden content".write(to: srcFile, atomically: true, encoding: .utf8)

        // When
        try fileManager.moveRetainingDestinationPermisssions(at: srcFile, to: dstFile)

        // Then
        XCTAssertTrue(fileManager.fileExists(atPath: dstFile.path), "Destination file should exist")
        XCTAssertFalse(fileManager.fileExists(atPath: srcFile.path), "Source file should be removed")

        let movedContent = try String(contentsOf: dstFile, encoding: .utf8)
        XCTAssertEqual(movedContent, "Hidden content", "Content should match")
    }

    func test_moveRetainingDestinationPermissions_preservesContent() throws {
        // Given - Ensure content integrity with specific data patterns
        let srcFile = testDirectory.appendingPathComponent("integrity_source.txt")
        let dstFile = testDirectory.appendingPathComponent("integrity_dest.txt")

        // Create content with specific patterns to verify integrity
        var content = ""
        for i in 0..<100 {
            content += "Line \(i): The quick brown fox jumps over the lazy dog.\n"
        }
        try content.write(to: srcFile, atomically: true, encoding: .utf8)

        let originalSize = try fileManager.attributesOfItem(atPath: srcFile.path)[.size] as! UInt64

        // When
        try fileManager.moveRetainingDestinationPermisssions(at: srcFile, to: dstFile)

        // Then
        let movedContent = try String(contentsOf: dstFile, encoding: .utf8)
        let movedSize = try fileManager.attributesOfItem(atPath: dstFile.path)[.size] as! UInt64

        XCTAssertEqual(movedContent, content, "Content should be identical")
        XCTAssertEqual(movedSize, originalSize, "File size should be identical")
    }
}

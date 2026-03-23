//
//  Copyright 2026, Jamf
//

@testable import Jamf_Sync
import XCTest
import CryptoKit

final class FileHashTests: XCTestCase {
    var fileHash: FileHash!
    var testDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()
        fileHash = FileHash.shared

        // Create a unique test directory
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileHashTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        // Clean up test directory
        if FileManager.default.fileExists(atPath: testDirectory.path) {
            try? FileManager.default.removeItem(at: testDirectory)
        }
        testDirectory = nil
        try await super.tearDown()
    }

    // MARK: - createSHA512Hash Tests

    func test_createSHA512Hash_withSimpleContent() async throws {
        // Given
        let testContent = "Hello, World!"
        let testFile = testDirectory.appendingPathComponent("test.txt")
        try testContent.write(to: testFile, atomically: true, encoding: .utf8)

        // Calculate expected hash
        let expectedHash = SHA512.hash(data: testContent.data(using: .utf8)!)
        let expectedHashString = Data(expectedHash).hexEncodedString()

        // When
        let result = try await fileHash.createSHA512Hash(filePath: testFile.path)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedHashString)
        XCTAssertEqual(result?.count, 128, "SHA512 hash should be 128 characters (64 bytes in hex)")
    }

    func test_createSHA512Hash_withEmptyFile() async throws {
        // Given
        let testFile = testDirectory.appendingPathComponent("empty.txt")
        try "".write(to: testFile, atomically: true, encoding: .utf8)

        // Calculate expected hash for empty data
        let expectedHash = SHA512.hash(data: Data())
        let expectedHashString = Data(expectedHash).hexEncodedString()

        // When
        let result = try await fileHash.createSHA512Hash(filePath: testFile.path)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedHashString)
    }

    func test_createSHA512Hash_withLargeFile() async throws {
        // Given - Create a file larger than the buffer size (1024 bytes)
        let largeContent = String(repeating: "A", count: 10000)
        let testFile = testDirectory.appendingPathComponent("large.txt")
        try largeContent.write(to: testFile, atomically: true, encoding: .utf8)

        // Calculate expected hash
        let expectedHash = SHA512.hash(data: largeContent.data(using: .utf8)!)
        let expectedHashString = Data(expectedHash).hexEncodedString()

        // When
        let result = try await fileHash.createSHA512Hash(filePath: testFile.path)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedHashString)
    }

    func test_createSHA512Hash_withBinaryData() async throws {
        // Given - Create a file with binary data
        let binaryData = Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD])
        let testFile = testDirectory.appendingPathComponent("binary.dat")
        try binaryData.write(to: testFile)

        // Calculate expected hash
        let expectedHash = SHA512.hash(data: binaryData)
        let expectedHashString = Data(expectedHash).hexEncodedString()

        // When
        let result = try await fileHash.createSHA512Hash(filePath: testFile.path)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedHashString)
    }

    func test_createSHA512Hash_withNonExistentFile() async throws {
        // Given
        let nonExistentFile = testDirectory.appendingPathComponent("nonexistent.txt")

        // When
        let result = try await fileHash.createSHA512Hash(filePath: nonExistentFile.path)

        // Then
        // FileHash.createSHA512Hash(filePath:) returns nil when the InputStream
        // cannot be created (e.g., when the file does not exist).
        XCTAssertNil(result, "Non-existent file should return nil hash")
    }

    func test_createSHA512Hash_withDirectory() async throws {
        // Given - Try to hash a directory instead of a file
        let directory = testDirectory.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // When/Then
        // InputStream throws an error when trying to read from a directory
        do {
            _ = try await fileHash.createSHA512Hash(filePath: directory.path)
            XCTFail("Should throw an error when hashing a directory")
        } catch {
            // Expected - verify the error message contains "directory"
            let errorMessage = (error as NSError).localizedDescription.lowercased()
            XCTAssertTrue(errorMessage.contains("directory"), "Error should indicate it's a directory")
        }
    }

    func test_createSHA512Hash_withMultipleFiles_sameContent() async throws {
        // Given - Two files with identical content
        let content = "Identical content"
        let file1 = testDirectory.appendingPathComponent("file1.txt")
        let file2 = testDirectory.appendingPathComponent("file2.txt")
        try content.write(to: file1, atomically: true, encoding: .utf8)
        try content.write(to: file2, atomically: true, encoding: .utf8)

        // When
        let hash1 = try await fileHash.createSHA512Hash(filePath: file1.path)
        let hash2 = try await fileHash.createSHA512Hash(filePath: file2.path)

        // Then
        XCTAssertNotNil(hash1)
        XCTAssertNotNil(hash2)
        XCTAssertEqual(hash1, hash2, "Files with identical content should have identical hashes")
    }

    func test_createSHA512Hash_withMultipleFiles_differentContent() async throws {
        // Given - Two files with different content
        let content1 = "Content A"
        let content2 = "Content B"
        let file1 = testDirectory.appendingPathComponent("fileA.txt")
        let file2 = testDirectory.appendingPathComponent("fileB.txt")
        try content1.write(to: file1, atomically: true, encoding: .utf8)
        try content2.write(to: file2, atomically: true, encoding: .utf8)

        // When
        let hash1 = try await fileHash.createSHA512Hash(filePath: file1.path)
        let hash2 = try await fileHash.createSHA512Hash(filePath: file2.path)

        // Then
        XCTAssertNotNil(hash1)
        XCTAssertNotNil(hash2)
        XCTAssertNotEqual(hash1, hash2, "Files with different content should have different hashes")
    }

    func test_createSHA512Hash_withUnicodeContent() async throws {
        // Given
        let unicodeContent = "Hello 世界 🌍 café"
        let testFile = testDirectory.appendingPathComponent("unicode.txt")
        try unicodeContent.write(to: testFile, atomically: true, encoding: .utf8)

        // Calculate expected hash
        let expectedHash = SHA512.hash(data: unicodeContent.data(using: .utf8)!)
        let expectedHashString = Data(expectedHash).hexEncodedString()

        // When
        let result = try await fileHash.createSHA512Hash(filePath: testFile.path)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedHashString)
    }

    func test_createSHA512Hash_withNewlineVariations() async throws {
        // Given - Test that different newline styles produce different hashes
        let unixNewline = "Line 1\nLine 2"
        let windowsNewline = "Line 1\r\nLine 2"

        let file1 = testDirectory.appendingPathComponent("unix.txt")
        let file2 = testDirectory.appendingPathComponent("windows.txt")
        try unixNewline.write(to: file1, atomically: true, encoding: .utf8)
        try windowsNewline.write(to: file2, atomically: true, encoding: .utf8)

        // When
        let hash1 = try await fileHash.createSHA512Hash(filePath: file1.path)
        let hash2 = try await fileHash.createSHA512Hash(filePath: file2.path)

        // Then
        XCTAssertNotNil(hash1)
        XCTAssertNotNil(hash2)
        XCTAssertNotEqual(hash1, hash2, "Different newline styles should produce different hashes")
    }

    func test_createSHA512Hash_bufferBoundary() async throws {
        // Given - Create a file exactly at the buffer size (1024 bytes)
        let exactBufferContent = String(repeating: "X", count: 1024)
        let testFile = testDirectory.appendingPathComponent("buffer.txt")
        try exactBufferContent.write(to: testFile, atomically: true, encoding: .utf8)

        // Calculate expected hash
        let expectedHash = SHA512.hash(data: exactBufferContent.data(using: .utf8)!)
        let expectedHashString = Data(expectedHash).hexEncodedString()

        // When
        let result = try await fileHash.createSHA512Hash(filePath: testFile.path)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedHashString)
    }

    func test_createSHA512Hash_multipleBuffers() async throws {
        // Given - Create a file that requires multiple buffer reads (3000 bytes = ~3 buffers)
        let multiBufferContent = String(repeating: "M", count: 3000)
        let testFile = testDirectory.appendingPathComponent("multibuffer.txt")
        try multiBufferContent.write(to: testFile, atomically: true, encoding: .utf8)

        // Calculate expected hash
        let expectedHash = SHA512.hash(data: multiBufferContent.data(using: .utf8)!)
        let expectedHashString = Data(expectedHash).hexEncodedString()

        // When
        let result = try await fileHash.createSHA512Hash(filePath: testFile.path)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result, expectedHashString)
    }

    // MARK: - Data Extension Tests

    func test_hexEncodedString_withSimpleData() {
        // Given
        let data = Data([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])

        // When
        let result = data.hexEncodedString()

        // Then
        XCTAssertEqual(result, "0123456789abcdef")
    }

    func test_hexEncodedString_withEmptyData() {
        // Given
        let data = Data()

        // When
        let result = data.hexEncodedString()

        // Then
        XCTAssertEqual(result, "")
    }

    func test_hexEncodedString_withSingleByte() {
        // Given
        let data = Data([0xFF])

        // When
        let result = data.hexEncodedString()

        // Then
        XCTAssertEqual(result, "ff")
    }

    func test_hexEncodedString_withLeadingZeros() {
        // Given
        let data = Data([0x00, 0x01, 0x0F])

        // When
        let result = data.hexEncodedString()

        // Then
        XCTAssertEqual(result, "00010f", "Leading zeros should be preserved")
    }

    func test_hexEncodedString_withAllZeros() {
        // Given
        let data = Data([0x00, 0x00, 0x00])

        // When
        let result = data.hexEncodedString()

        // Then
        XCTAssertEqual(result, "000000")
    }

    func test_hexEncodedString_withAllOnes() {
        // Given
        let data = Data([0xFF, 0xFF, 0xFF])

        // When
        let result = data.hexEncodedString()

        // Then
        XCTAssertEqual(result, "ffffff")
    }

    func test_hexEncodedString_lengthCorrect() {
        // Given
        let data = Data([0x12, 0x34, 0x56, 0x78])

        // When
        let result = data.hexEncodedString()

        // Then
        XCTAssertEqual(result.count, data.count * 2, "Hex string should be twice the length of data")
    }

    // MARK: - Concurrent Access Tests

    func test_concurrentHashCalculation() async throws {
        // Given - Create multiple test files
        let fileCount = 5
        var files: [URL] = []
        for i in 0..<fileCount {
            let file = testDirectory.appendingPathComponent("concurrent\(i).txt")
            try "Content \(i)".write(to: file, atomically: true, encoding: .utf8)
            files.append(file)
        }

        // When - Hash all files concurrently
        let results = await withTaskGroup(of: (Int, String?).self) { group in
            for (index, file) in files.enumerated() {
                group.addTask {
                    let hash = try? await self.fileHash.createSHA512Hash(filePath: file.path)
                    return (index, hash)
                }
            }

            var hashes: [Int: String?] = [:]
            for await (index, hash) in group {
                hashes[index] = hash
            }
            return hashes
        }

        // Then
        XCTAssertEqual(results.count, fileCount)
        for i in 0..<fileCount {
            XCTAssertNotNil(results[i] ?? nil, "Hash \(i) should not be nil")
        }
    }
}

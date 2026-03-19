//
//  Copyright 2024, Jamf
//

import Foundation
import CryptoKit

actor FileHash {
    static var shared: FileHash = FileHash()

    func createSHA512Hash(filePath: String) throws -> String? {
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }

        guard let input = InputStream(fileAtPath: filePath) else {
            return nil
        }

        defer {
            input.close()
        }
        input.open()

        // Check stream status after opening - if file doesn't exist, status will be .error
        if input.streamStatus == .error {
            return nil
        }

        var hasher = SHA512()
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            if read < 0 {
                //Stream error occured
                throw input.streamError!
            } else if read == 0 {
                //EOF
                break
            }
            var data = Data()
            data.append(buffer, count: read)
            hasher.update(data: data)
        }
        let hash = hasher.finalize()
        return Data(hash).hexEncodedString()
    }
}

extension Data {
    func hexEncodedString() -> String {
        return self.map { String(format: "%02hhx", $0) }.joined()
    }
}

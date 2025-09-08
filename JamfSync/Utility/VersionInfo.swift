//
//  Copyright 2024, Jamf
//

import Foundation

class VersionInfo {
    func getDisplayVersion() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? ""
        return "Version: \(version) (\(build))"
    }

    static func versionIsAtLeast(version: String, major: Int, minor: Int) -> Bool {
        let versionParts = version.split(separator: ".")
        if versionParts.count >= 2 {
            if let majorVersion = Int(versionParts[0]), let minorVersion = Int(versionParts[1]) {
                if majorVersion > major {
                    return true
                } else if majorVersion == major && minorVersion >= minor {
                    return true
                }
            }
        }
        return false
    }
}

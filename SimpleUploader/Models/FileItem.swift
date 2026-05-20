import Foundation

struct FileItem: Identifiable {
    let id = UUID()
    let url: URL
    var name: String { url.lastPathComponent }
    var isDirectory: Bool { (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false }
    var size: Int64? {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) }
    }
}

import Foundation
import Combine
import AppKit

@MainActor
class UploaderViewModel: ObservableObject {
    @Published var sourceURL: URL?
    @Published var destinationURL: URL?
    @Published var files: [FileItem] = []
    @Published var progress: Double = 0.0
    @Published var isUploading: Bool = false
    @Published var logs: [LogMessage] = []

    private var isCanceled = false

    func pickSourceFolder() async -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return url
    }

    func pickDestinationFolder() async -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return url
    }

    func enumerateFiles() async {
        files = []
        guard let source = sourceURL else { return }
        let fm = FileManager.default
        var allFiles: [FileItem] = []
        let enumerator = fm.enumerator(at: source, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey], options: [.skipsHiddenFiles, .skipsPackageDescendants])
        while let item = enumerator?.nextObject() as? URL {
            let resourceValues = try? item.resourceValues(forKeys: [.isDirectoryKey])
            if resourceValues?.isDirectory == true { continue }
            allFiles.append(FileItem(url: item))
        }
        files = allFiles.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    func startUpload() {
        Task {
            await uploadFiles()
        }
    }

    func cancelUpload() {
        isCanceled = true
    }

    private func log(_ message: String) {
        let m = LogMessage(message: message)
        logs.append(m)
    }

    private func uploadFiles() async {
        guard let source = sourceURL, let destination = destinationURL else { return }
        isCanceled = false
        isUploading = true
        progress = 0.0
        logs = []

        await enumerateFiles()
        let total = Double(files.count)
        if total == 0 {
            log("No files to upload")
            isUploading = false
            return
        }

        let fm = FileManager.default
        var completed: Double = 0
        for file in files {
            if isCanceled { log("Upload canceled"); break }
            let relativePath = file.url.path.replacingOccurrences(of: source.path, with: "")
            let destFile = destination.appendingPathComponent(relativePath)
            let destDir = destFile.deletingLastPathComponent()
            do {
                if !fm.fileExists(atPath: destDir.path) {
                    try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
                }
                if fm.fileExists(atPath: destFile.path) {
                    try fm.removeItem(at: destFile)
                }
                try fm.copyItem(at: file.url, to: destFile)
                completed += 1
                progress = completed / total
                log("Uploaded: \(relativePath)")
            } catch {
                log("Failed to upload \(relativePath): \(error.localizedDescription)")
                completed += 1
                progress = completed / total
            }
        }

        if !isCanceled {
            log("Upload finished")
        }
        isUploading = false
        isCanceled = false
    }
}

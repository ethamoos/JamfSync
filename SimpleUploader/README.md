SimpleUploader
===============

A minimal macOS SwiftUI app that lets the user select a local source folder and a destination "distribution point" (also a local folder), lists files in the source, and uploads (copies) them recursively to the destination while showing progress and log messages.

How to use
---------
1. Open Xcode and create a new macOS App project (App, SwiftUI) named `SimpleUploader`. Choose Swift and SwiftUI.
2. Replace the generated files with the source files in this folder, or add these files to the project and ensure the target membership is set to your app target.
3. Build and run on macOS (macOS 12+ recommended).

Files
-----
- SimpleUploaderApp.swift — App entry point
- ContentView.swift — Main UI (folder pickers, file list, progress, logs)
- UploaderViewModel.swift — Core logic: enumerates files and copies them to destination, provides progress and logging
- FileItem.swift — A tiny model for files
- LogMessage.swift — Simple log message model

Notes
-----
- This is intentionally simple and uses local file system copy operations. It does not integrate with Jamf APIs — the destination distribution point is represented as a local folder (like the original app's destination).
- On collisions, files are overwritten.
- Cancellation is cooperative; long-running copy operations will check cancellation between files.

Edge cases
----------
- Insufficient disk space or copy failures are logged and the upload continues to the next file.
- File name collisions: existing files at destination are overwritten.
- Very large sets of files: enumeration happens first which may take time; this app is designed for small-to-medium collections.

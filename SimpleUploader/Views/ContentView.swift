import SwiftUI

struct ContentView: View {
    @StateObject private var vm = UploaderViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Source Folder:")
                    HStack {
                        Text(vm.sourceURL?.path ?? "(none)")
                            .lineLimit(1)
                        Button("Choose...") {
                            Task {
                                if let url = await vm.pickSourceFolder() {
                                    vm.sourceURL = url
                                    await vm.enumerateFiles()
                                }
                            }
                        }
                    }
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Destination DP:")
                    HStack {
                        Text(vm.destinationURL?.path ?? "(none)")
                            .lineLimit(1)
                        Button("Choose...") {
                            Task {
                                if let url = await vm.pickDestinationFolder() {
                                    vm.destinationURL = url
                                }
                            }
                        }
                    }
                }
            }
            .padding()

            Divider()

            HStack {
                Text("Files to upload: \(vm.files.count)")
                Spacer()
                if vm.isUploading {
                    Button("Cancel") { vm.cancelUpload() }
                } else {
                    Button("Start Upload") { vm.startUpload() }
                        .disabled(vm.sourceURL == nil || vm.destinationURL == nil || vm.files.isEmpty)
                }
            }
            .padding([.leading, .trailing, .bottom])

            ProgressView(value: vm.progress)
                .padding([.leading, .trailing])

            List(vm.files) { file in
                HStack {
                    Text(file.name)
                    Spacer()
                    if let size = file.size {
                        Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading) {
                Text("Log Messages")
                List(vm.logs) { log in
                    HStack {
                        Text(DateFormatter.localizedString(from: log.date, dateStyle: .none, timeStyle: .medium))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(log.message)
                    }
                }
            }
            .frame(height: 180)
        }
        .frame(minWidth: 700, minHeight: 600)
    }
}

#if DEBUG
import AppKit
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif

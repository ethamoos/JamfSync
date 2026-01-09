//
//  Copyright 2024, Jamf
//

import SwiftUI

struct AboutView: View {
    
    @AppStorage("optOut") private var optOut: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image("JamfSync_64")
                VStack(alignment: .leading) {
                    Text("Jamf Sync")
                        .font(.title)
                    Text("\(VersionInfo().getDisplayVersion())")
                    
                    Text("Jamf Sync helps synchronize content to Jamf Pro distribution points.\n\nCopyright 2024, Jamf")
                        .padding([.top])
                }
            }
            Toggle("Opt out of analytics", isOn: $optOut)
                        .padding()
        }
        .padding()
        .frame(minWidth: 530, minHeight: 150)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

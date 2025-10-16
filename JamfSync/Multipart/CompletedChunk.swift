//
//  Copyright 2024, Jamf
//

import Foundation

class CompletedChunk {
    var partNumber: Int
    var eTag: String
    
    init(partNumber: Int, eTag: String) {
        self.partNumber = partNumber
        self.eTag = eTag
    }
}

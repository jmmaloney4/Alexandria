// Copyright © 2018-2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftCLI
import Pergamon

class CatCommand: Command {
    var name = "cat"
    
    var hashes = CollectedParameter()
    
    func execute() throws {
        let shas = try hashes.value.map({ try SHA256(withHex: $0) })
        for sha in shas {
            let file = try Config.default.library.getFile(sha)
            print(String(data: file.object.data, encoding: .utf8) ?? "\(file.object.data.count) Bytes", separator: "")
        }
    }
    
}

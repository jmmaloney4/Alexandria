// Copyright © 2018-2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftCLI
import Pergamon

class UpdateCommand: Command {
    var name = "update"
    
    var hash = Parameter()
    var path = Parameter()
    
    func execute() throws {
        let sha = try SHA256(withHex: hash.value)
        let url = URL(fileURLWithPath: path.value)
        
        let original = try Config.default.library.getFile(sha)
        let new = try File(fromFileSystem: url)
        let updated = try Config.default.library.updateFile(original, to: new)
        
        if original.name != updated.name {
            print("\(original.name) -> \(updated.name)    \(updated.hash)")
        } else {
            print("\(updated.name)    \(updated.hash)")
        }
    }
}

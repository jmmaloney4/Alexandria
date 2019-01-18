// Copyright © 2018-2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

struct History: IteratorProtocol {
    typealias Element = Version
    var last: Version
    
    mutating func next() -> Version? {
        return nil
    }
    
    init(fromFile file: File) {
        self.last = Version(file: file)
    }
}

struct Version {
    var file: File
}

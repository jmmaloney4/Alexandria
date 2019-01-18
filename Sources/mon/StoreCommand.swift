// Copyright © 2018-2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftCLI
import Pergamon

class StoreCommand: Command {
    var name = "store"
    var shortDescription = "Add a file to the library."
    let paths = CollectedParameter()
    // let stdin = Flag("--stdin")
    let silent = Flag("-q", "--silent")
    let recursive = Flag("-r", "--recursive")
    
    func execute() throws {
        let urls = paths.value.map({ URL(fileURLWithPath: $0) })
            .filter { url in
                do {
                    guard try url.checkResourceIsReachable() else { fatalError() }
                } catch { fatalError() }
                return true
        }
        
        var files: [File] = []
        for url in urls {
            let file = try File(fromFileSystem: url)
            try Config.default.library.addFile(file)
            files.append(file)
        }
        
        printStatus(files: files)
    }
    
    func printStatus(files: [File]) {
        let longestName = files.map({ $0.name.count }).max()!
        let width = longestName + 4
        
        for file in files {
            let spaces = width - file.name.count
            
            var str = file.name
            str.insert(contentsOf: Array(repeating: " ", count: spaces), at: str.endIndex)
            str.append(file.hash.hex)
            print(str)
        }
    }
}


//
//  HashObjectCommand.swift
//  Alexandria
//
//  Created by Jack Maloney on 1/14/19.
//

import Foundation
import SwiftCLI

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
                    guard try url.checkResourceIsReachable() else { throw AlexandriaError.fileDoesNotExist(url.path, false) }
                } catch { fatalError() }
                return true
        }
        
        for url in urls {
            // let file = 
            // Config.default.library.addFile()
        }
    }
    
}


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


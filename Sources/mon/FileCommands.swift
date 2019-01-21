//
//  FileCommands.swift
//  mon
//
//  Created by Jack Maloney on 1/20/19.
//

import Foundation
import Pergamon
import SwiftCLI

class FileCommandGroup: CommandGroup {
    var name = "file"
    var shortDescription = "Commands that manipulate files"
    var children: [Routable] = [CatFile(), StoreFile(), UpdateFile()]
}

class CatFile: Command {
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

class StoreFile: Command {
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

class UpdateFile: Command {
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

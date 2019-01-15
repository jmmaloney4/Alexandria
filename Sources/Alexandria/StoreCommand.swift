//
//  HashObjectCommand.swift
//  Alexandria
//
//  Created by Jack Maloney on 1/14/19.
//

import Foundation
import SwiftCLI

class StoreCommand: Command {
    var name: String = "store"
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
        
        guard let objs = try? self.storeUrls(urls) else {
            fatalError()
        }
        
        do {
            try self.printStatus(urls: urls, objs: objs)
        } catch {
            fatalError()
        }
    }
    
    func storeUrls(_ urls: [URL]) throws -> [Object] {
        var objs: [Object] = []
        for url in urls {
            let data = try Data(contentsOf: url)
            guard let obj = Config.default.library.addData(data) else {
                fatalError()
            }
            objs.append(obj)
        }
        return objs
    }
    
    func printStatus(urls: [URL], objs: [Object]) throws {
        let filenames = urls.map({ $0.lastPathComponent })
        let longestPath = filenames.map({ $0.count }).max()!
        let width = longestPath + 4
        
        guard urls.count == objs.count else {
            fatalError()
        }
        
        for (fname, obj) in zip(filenames, objs) {
            let spaces = width - fname.count
            
            var str = fname
            str.insert(contentsOf: Array(repeating: " ", count: spaces), at: str.endIndex)
            str.append(obj.hash.hex)
            print(str)
        }
    }
}

class CatCommand: Command {
    var name = "cat"
    var hashes = CollectedParameter()

    func execute() throws {
        let shas = hashes.value.compactMap({ try? SHA256(withHex: $0) })
        
        for sha in shas {
            guard let obj = Config.default.library.getObject(sha) else {
                fatalError()
            }
            print(String(data: obj.data, encoding: .utf8) ?? obj.data, separator: "")
        }
    }
    
    
}

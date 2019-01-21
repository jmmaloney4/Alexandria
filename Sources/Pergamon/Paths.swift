//
//  Paths.swift
//  mon
//
//  Created by Jack Maloney on 1/20/19.
//

import Foundation

extension Library {
    struct PathResolver {
        var lib: Library
        
        var objectDir: URL {
            return lib.path.appendingPathComponent("obj")
        }
        
        var indexDir: URL {
            return lib.path.appendingPathComponent("index")
        }
        
        func getDBPathForHash(_ sha: SHA256) -> URL {
            let hex = sha.hex
            let splitIndex = hex.index(hex.startIndex, offsetBy: 2)
            let part1 = hex.prefix(upTo: splitIndex)
            let part2 = hex.suffix(from: splitIndex)
            return self.objectDir.appendingPathComponent("\(part1)/\(part2)", isDirectory: false)
        }
        
        func getDBPrefixDirPath(_ sha: SHA256) -> URL {
            let hex = sha.hex
            let splitIndex = hex.index(hex.startIndex, offsetBy: 2)
            let part1 = hex.prefix(upTo: splitIndex)
            return self.objectDir.appendingPathComponent(String(part1), isDirectory: true)
        }
        
        func getIndexFileForHash(_ sha: SHA256) -> URL {
            return self.indexDir.appendingPathComponent(sha.hex)
        }
        
        func getProjectPathForName(_ name: String) -> URL {
            return lib.path.appendingPathComponent("projects").appendingPathComponent(name)
        }
    }
}

//
//  Library.swift
//  Alexandria
//
//  Created by Jack Maloney on 1/17/19.
//

import Foundation

struct Library {
    var path: URL
    
    struct PathResolver {
        var lib: Library
        
        func getDBPathForHash(_ sha: SHA256) -> URL {
            let hex = sha.hex
            let splitIndex = hex.index(hex.startIndex, offsetBy: 2)
            let part1 = hex.prefix(upTo: splitIndex)
            let part2 = hex.suffix(from: splitIndex)
            return self.lib.path.appendingPathComponent("\(part1)/\(part2)", isDirectory: false)
        }
        
        func getDBPrefixDirPath(_ sha: SHA256) -> URL {
            let hex = sha.hex
            let splitIndex = hex.index(hex.startIndex, offsetBy: 2)
            let part1 = hex.prefix(upTo: splitIndex)
            return self.lib.path.appendingPathComponent(String(part1), isDirectory: true)
        }
    }
    var resolver: PathResolver { return PathResolver(lib: self) }
    
    init(atPath path: URL) {
        self.path = path
    }
    
    init(atPath path: String) {
        self.init(atPath: URL(fileURLWithPath: path))
    }
    
    func getFile(_ sha: SHA256) throws -> File {
        return try File(fromDatabase: sha, withResolver: self.resolver)
    }
    
    func addFile(_ file: File) throws {
        try writeObject(file.object)
        try writeObject(file.meta.makeObject())
    }
    
    func writeObject(_ obj: Object) throws {
        if !FileManager.default.fileExists(atPath: self.resolver.getDBPrefixDirPath(obj.hash).path) {
            try FileManager.default.createDirectory(at: self.resolver.getDBPrefixDirPath(obj.hash), withIntermediateDirectories: true)
        }
        
        guard var toWrite = obj.kind.rawValue.data(using: .utf8) else { fatalError() }
        toWrite.append(obj.data)
        try toWrite.write(to: resolver.getDBPathForHash(obj.hash))
    }
}

// Copyright © 2018-2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SQLite3

public struct Library {
    var path: URL
    
    var resolver: PathResolver { return PathResolver(lib: self) }
    
    init(atPath path: URL) {
        self.path = path
    }
    
    init(atPath path: String) {
        self.init(atPath: URL(fileURLWithPath: path))
    }
    
    public func getFile(_ sha: SHA256) throws -> File {
        return try File(fromDatabase: sha, withResolver: self.resolver)
    }
    
    public func addFile(_ file: File) throws {
        try writeObject(file.object)
        try writeObject(file.meta.makeObject())
    }
    
    public func updateFile(_ original: File, to file: File) throws -> File {
        var rv = file
        rv.meta.original = original.hash
        try self.addFile(rv)
        return rv
    }
    
    func writeObject(_ obj: Object) throws {
        if !FileManager.default.fileExists(atPath: self.resolver.getDBPrefixDirPath(obj.hash).path) {
            try FileManager.default.createDirectory(at: self.resolver.getDBPrefixDirPath(obj.hash), withIntermediateDirectories: true)
        }
        
        guard var toWrite = obj.kind.rawValue.data(using: .utf8) else { fatalError() }
        toWrite.append(contentsOf: [0])
        toWrite.append(obj.data)
        try toWrite.write(to: resolver.getDBPathForHash(obj.hash))
    }
}

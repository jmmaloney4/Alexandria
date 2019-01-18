// Copyright © 2018-2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public struct File {
    var object: Object
    var meta: Metadata
    
    public init(fromFileSystem path: URL) throws {
        guard FileManager.default.fileExists(atPath: path.path) else { fatalError() }
        self.object = Object(withData: try Data(contentsOf: path), kind: .blob)
        self.meta = try Metadata(forFileAtPath: path, hash: self.object.hash)
    }
    
    internal init(fromDatabase hash: SHA256, withResolver resolver: Library.PathResolver) throws {
        let metaPath = resolver.getDBPathForHash(hash)
        guard try metaPath.checkResourceIsReachable() else { fatalError() }
        let metaObj = try Object(atURL: metaPath)
        self.meta = try JSONDecoder().decode(Metadata.self, from: metaObj.data)
        
        self.object = try Object(loadHash: self.meta.object, withResolver: resolver)
    }
    
    public var hash: SHA256 {
        return self.meta.makeObject().hash
    }
    
    public var name: String {
        return self.meta.name
    }
    
    struct Metadata: Codable {
        var name: String
        var author: User
        var object: SHA256
        var original: SHA256?
        var created: Date
        
        enum CodingKeys: String, CodingKey {
            case name
            case author
            case object
            case original
            case created
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            
            self.name = try values.decode(String.self, forKey: .name)
            self.author = try values.decode(User.self, forKey: .author)
            self.object = try values.decode(SHA256.self, forKey: .object)
            self.original = try? values.decode(SHA256.self, forKey: .original)
            self.created = DateForString(try values.decode(String.self, forKey: .created)).expect("Couldn't decode date")
        }
        
        init(forFileAtPath path: URL, hash: SHA256) throws {
            self.name = path.lastPathComponent
            self.author = Config.default.user
            self.object = hash
            self.original = nil
            self.created = Date()
        }
        
        func makeObject() -> Object {
            do {
                return Object(withData: try JSONEncoder().encode(self), kind: .meta)
            } catch { fatalError() }
        }
    }
}

struct Version {
    var data: Object
    var meta: File.Metadata
}

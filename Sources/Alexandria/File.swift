//
//  File.swift
//  Alexandria
//
//  Created by Jack Maloney on 1/17/19.
//

import Foundation

struct File {
    var object: Object
    var meta: Metadata
    
    init(fromFileSystem path: URL) throws {
        guard FileManager.default.fileExists(atPath: path.path) else { fatalError() }
        self.object = Object(withData: try Data(contentsOf: path), kind: .blob)
        self.meta = try Metadata(forFileAtPath: path, hash: self.object.hash)
    }
    
    init(fromDatabase hash: SHA256, withResolver resolver: Library.PathResolver) throws {
        let metaPath = resolver.getDBPathForHash(hash)
        guard try metaPath.checkResourceIsReachable() else { fatalError() }
        let metaObj = try Object(atURL: metaPath)
        self.meta = try JSONDecoder().decode(Metadata.self, from: metaObj.data)
        
        self.object = try Object(loadHash: self.meta.object, withResolver: resolver)
    }
    
    var hash: SHA256 {
        return self.meta.makeObject().hash
    }
    
    var name: String {
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

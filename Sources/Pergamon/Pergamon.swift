// Copyright © 2018-2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Cryptor
import Optionals

public struct Object {
    public private(set) var data: Data
    public private(set) var kind: Kind
    public var hash: SHA256 { return SHA256(withData: self.data) }
    
    init(withData data: Data, kind: Kind) {
        self.data = data
        self.kind = kind
    }
    
    init(atURL url: URL) throws {
        let buf = try Data(contentsOf: url)
        guard let prefix = String(data: buf.prefix(while: { $0 != 0 }), encoding: .utf8) else { fatalError() }
        guard let kind = Kind(rawValue: prefix) else { fatalError() }
        
        self.init(withData: buf.advanced(by: prefix.count + 1), kind: kind)
    }
    
    init(loadHash hash: SHA256, withResolver resolver: Library.PathResolver) throws {
        try self.init(atURL: resolver.getDBPathForHash(hash))
    }
    
    public enum Kind: String {
        case blob
        case meta
    }
 }

public struct User: Codable, CustomStringConvertible {
    public private(set) var name: String
    public private(set) var email: String
    
    init(name: String? = nil, email: String? = nil) {
        self.name = name ?? "Unknown"
        self.email = email ?? "Unknown"
    }
 
    public var description: String {
        return "\(self.name) <\(self.email)>"
    }
}

// Could later use https://github.com/IBM-Swift/Configuration.git
public struct Config: Codable {
    public private(set) var user: User
    private var libraryPath: String
    
    enum CodingKeys: String, CodingKey {
        case user
        case library
    }
    
    init(withPath path: URL) throws {
        let cfg = try JSONDecoder().decode(Config.self, from: try Data(contentsOf: path))
        self.user = cfg.user
        self.libraryPath = cfg.libraryPath
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        user = try values.decode(User.self, forKey: .user)
        libraryPath = try values.decode(String.self, forKey: .library)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user, forKey: .user)
        try container.encode(libraryPath, forKey: .library)
    }
    
    public static var `default` = try! Config(withPath: URL(fileURLWithPath: NSString(string: "~/.mon/config.json").expandingTildeInPath))
    
    public var library: Library {
        return Library(atPath: NSString(string: self.libraryPath).expandingTildeInPath)
    }
}

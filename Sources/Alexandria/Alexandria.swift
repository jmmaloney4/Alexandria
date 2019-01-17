import Foundation
import Cryptor
import SwiftyJSON
import Optionals

struct SHA256: Codable, CustomStringConvertible {
    var bytes: [UInt8]
    
    init(withData data: Data) {
        guard let digest = Digest(using: .sha256).update(data: data) else {
            fatalError()
        }
        self.bytes = digest.final()
    }
    
    init(withHex hex: String) throws {
        self.bytes = hex.hexa2Bytes
        guard self.bytes.count == 32 else {
            fatalError()
        }
    }
    
    var hex: String {
        return self.bytes.reduce(String(), { $0.appendingFormat("%02x", $1) })
    }
    var description: String { return self.hex }
}

extension StringProtocol {
    var hexa2Bytes: [UInt8] {
        let hexa = Array(self)
        return stride(from: 0, to: count, by: 2).compactMap { UInt8(String(hexa[$0...$0.advanced(by: 1)]), radix: 16) }
    }
}

struct Object {
    var data: Data
    var kind: Kind
    var hash: SHA256 { return SHA256(withData: self.data) }
    
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
    
    enum Kind: String {
        case blob
        case meta
    }
 }

func CurrentTimeString() -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return fmt.string(from: Date())
}

func DateForString(_ str: String) -> Date? {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return fmt.date(from: str)
}

struct User: Codable, CustomStringConvertible {
    var name: String
    var email: String
    
    init(name: String? = nil, email: String? = nil) {
        self.name = name ?? "Unknown"
        self.email = email ?? "Unknown"
    }
 
    var description: String {
        return "\(self.name) <\(self.email)>"
    }
}

// Could later use https://github.com/IBM-Swift/Configuration.git
struct Config: Codable {
    var user: User
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
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        user = try values.decode(User.self, forKey: .user)
        libraryPath = try values.decode(String.self, forKey: .library)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user, forKey: .user)
        try container.encode(libraryPath, forKey: .library)
    }
    
    static var `default` = try! Config(withPath: URL(fileURLWithPath: NSString(string: "~/.alex/config.json").expandingTildeInPath))
    
    var library: Library {
        return Library(atPath: NSString(string: self.libraryPath).expandingTildeInPath)
    }
}

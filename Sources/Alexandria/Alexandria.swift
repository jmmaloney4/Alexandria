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
    
    func addFile(_ file: File) {
        
    }
    
    
    func writeObject(_ obj: Object) throws {
        if !FileManager.default.fileExists(atPath: self.resolver.getDBPrefixDirPath(obj.hash).path) {
            try FileManager.default.createDirectory(at: self.resolver.getDBPrefixDirPath(obj.hash), withIntermediateDirectories: true)
        }
        
        guard var toWrite = obj.kind.rawValue.data(using: .utf8) else { fatalError() }
        toWrite.append(obj.data)
        try toWrite.write(to: path)
    }
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

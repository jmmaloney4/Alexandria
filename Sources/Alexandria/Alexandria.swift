import Foundation
import Cryptor
import SwiftyJSON

struct SHA256: CustomStringConvertible {
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
    var meta: JSON
    var hash: SHA256 { return SHA256(withData: self.data) }
    
    init(withData data: Data, meta: JSON? = nil) {
        self.data = data
        self.meta = meta ?? [:]
        self.meta["created"] = JSON(CurrentTimeString())
        self.meta["author"] = JSON("John Doe")
    }                                                                                                               
}

func CurrentTimeString() -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return fmt.string(from: Date())
}

struct Library {
    var path: URL
    
    init(atPath path: URL) {
        self.path = path
    }
    
    init(atPath path: String) {
        self.init(atPath: URL(fileURLWithPath: path))
    }
    
    func getDBPathForHash(_ sha: SHA256) -> URL {
        let hex = sha.hex
        let splitIndex = hex.index(hex.startIndex, offsetBy: 2)
        let part1 = hex.prefix(upTo: splitIndex)
        let part2 = hex.suffix(from: splitIndex)
        return self.path.appendingPathComponent("\(part1)/\(part2)", isDirectory: true)
    }
    func getBlobFilePathForHash(_ sha: SHA256) -> URL { return self.getDBPathForHash(sha).appendingPathComponent("blob") }
    func getMetaFilePathForHash(_ sha: SHA256) -> URL { return self.getDBPathForHash(sha).appendingPathComponent("meta.json") }
    
    func getObject(_ sha: SHA256) -> Object? {
        guard FileManager.default.fileExists(atPath: self.getDBPathForHash(sha).path) else {
            return nil
        }

        do {
            return Object(withData: try Data(contentsOf: self.getBlobFilePathForHash(sha)))
        } catch {
            return nil
        }
    }
    
    func writeObject(_ obj: Object) throws {
        try FileManager.default.createDirectory(at: self.getDBPathForHash(obj.hash), withIntermediateDirectories: true)
        try obj.data.write(to: self.getBlobFilePathForHash(obj.hash))
        try obj.meta.rawData().write(to: self.getMetaFilePathForHash(obj.hash))
    }
    
    func addData(_ data: Data) -> Object? {
        
        
        let obj = Object(withData: data)
        try! self.writeObject(obj)
        
        assert(FileManager.default.fileExists(atPath: self.getBlobFilePathForHash(obj.hash).path))
        
        return obj
    }
}

struct User: CustomStringConvertible {
    var name: String
    var email: String
    
    init(name: String?, email: String?) {
        self.name = name ?? "Unknown"
        self.email = email ?? "Unknown"
    }
    
    var description: String {
        return "\(self.name) <\(self.email)>"
    }
}

// Could later use https://github.com/IBM-Swift/Configuration.git
struct Config {
    var json: JSON
    
    init(withPath path: String) throws {
        self.json = JSON(data: try Data(contentsOf: URL(fileURLWithPath: path)))
    }
    
    static var `default` = try! Config(withPath: NSString(string: "~/.alex/config.json").expandingTildeInPath)
    
    var user: User {
        return User(name: self.json["user"]["name"].string, email: self.json["user"]["email"].string)
    }
    
    var library: Library {
        return Library(atPath: NSString(string: self.json["library"].string!).expandingTildeInPath)
    }
}

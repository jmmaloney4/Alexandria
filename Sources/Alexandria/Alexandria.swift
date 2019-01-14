import Foundation
import Cryptor

struct SHA256: CustomStringConvertible {
    var bytes: [UInt8]
    
    init(withData data: Data) {
        guard let digest = Digest(using: .sha256).update(data: data) else {
            fatalError()
        }
        self.bytes = digest.final()
    }
    
    var hex: String {
        return self.bytes.reduce(String(), { $0.appendingFormat("%02x", $1) })
    }
    var description: String { return self.hex }
}

struct Object {
    var data: Data
    var hash: SHA256 { return SHA256(withData: self.data) }
    
    init(withData data: Data) {
        self.data = data
    }
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
    
    func addData(_ data: Data) -> Object? {
        let obj = Object(withData: data)
        
        try! FileManager.default.createDirectory(at: self.getDBPathForHash(obj.hash), withIntermediateDirectories: true)
        try! obj.data.write(to: self.getBlobFilePathForHash(obj.hash))
        
        assert(FileManager.default.fileExists(atPath: self.getBlobFilePathForHash(obj.hash).path))
        
        return obj
    }
}
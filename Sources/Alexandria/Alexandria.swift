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
    
    var dbPath: String {
        let hex = self.hex
        let splitIndex = hex.index(hex.startIndex, offsetBy: 2)
        let part1 = hex.prefix(upTo: splitIndex)
        let part2 = hex.suffix(from: splitIndex)
        return "\(part1)/\(part2)"
    }
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
    
    func getObject(_ sha: SHA256) -> Object? {
        let objPath = self.path.appendingPathComponent(sha.dbPath)

        guard FileManager.default.fileExists(atPath: objPath.path) else {
            return nil
        }

        do {
            return Object(withData: try Data(contentsOf: objPath.appendingPathComponent("blob")))
        } catch {
            return nil
        }
    }
    
    func addData(_ data: Data) -> Object? {
        let obj = Object(withData: data)
        let objPath = self.path.appendingPathComponent(obj.hash.dbPath, isDirectory: true)
        
        try! FileManager.default.createDirectory(at: objPath, withIntermediateDirectories: true)
        try! obj.data.write(to: objPath.appendingPathComponent("blob"))
        
        assert(FileManager.default.fileExists(atPath: objPath.path))
        
        return obj
    }
}

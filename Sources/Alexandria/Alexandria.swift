import Foundation
import Cryptor

struct SHA256 {
    var bytes: [UInt8]
    
    init(withData data: Data) {
        guard let digest = Digest(using: .sha256).update(data: data) else {
            fatalError()
        }
        self.bytes = digest.final()
    }
    
    var hex: String {
        return self.bytes.reduce("", { $0.appendingFormat("%02x", $1) })
    }
    
    var dbPath: String {
        let hex = self.hex
        let splitIndex = hex.index(hex.startIndex, offsetBy: 2)
        let part1 = hex.prefix(upTo: splitIndex)
        let part2 = hex.suffix(from: splitIndex)
        return "\(part1)/\(part2)"
    }
}

struct Object {
    var hash: SHA256 {
        return SHA256(withData: self.data)
    }
    var data: Data
    
    init(withData data: Data) {
        self.data = data
    }
    
    init(withPath path: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            fatalError()
        }
        self.data = data
    }
    
    func getDbPath() -> String {
        return ""
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
        
    }
}

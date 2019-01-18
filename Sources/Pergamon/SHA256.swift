//
//  SHA256.swift
//  Cryptor
//
//  Created by Jack Maloney on 1/17/19.
//

import Foundation
import Cryptor

public struct SHA256: Codable, CustomStringConvertible {
    public internal(set) var bytes: [UInt8]
    
    public init(withData data: Data) {
        guard let digest = Digest(using: .sha256).update(data: data) else {
            fatalError()
        }
        self.bytes = digest.final()
    }
    
    public init(withHex hex: String) throws {
        self.bytes = hex.hexa2Bytes
        guard self.bytes.count == 32 else {
            fatalError()
        }
    }
    
    public var hex: String {
        return self.bytes.reduce(String(), { $0.appendingFormat("%02x", $1) })
    }
    public var description: String { return self.hex }
}

fileprivate extension StringProtocol {
    var hexa2Bytes: [UInt8] {
        let hexa = Array(self)
        return stride(from: 0, to: count, by: 2).compactMap { UInt8(String(hexa[$0...$0.advanced(by: 1)]), radix: 16) }
    }
}

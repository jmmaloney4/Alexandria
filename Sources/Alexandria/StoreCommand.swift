//
//  HashObjectCommand.swift
//  Alexandria
//
//  Created by Jack Maloney on 1/14/19.
//

import Foundation
import SwiftCLI

class StoreCommand: Command {
    var name: String = "store"
    let paths = CollectedParameter()
    func execute() throws {
        var objs: [Object] = []
        for path in paths.value {
            let url = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: url)
            guard let obj = Config.default.library.addData(data) else {
                fatalError()
            }
            objs.append(obj)
        }
        
        let longestPath = paths.value.map({ URL(fileURLWithPath: $0).lastPathComponent.count }).max()!
        let width = longestPath + 4
        
        for (k, path) in paths.value.enumerated() {
            let spaces = width - path.count
            
            var str = path
            str.insert(contentsOf: Array(repeating: " ", count: spaces), at: str.endIndex)
            str.append(objs[k].hash.hex)
           
            print(str)
        }
    }
    
    
    
    
}

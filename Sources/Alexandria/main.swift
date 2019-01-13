//
//  main.swift
//  Alexandria
//
//  Created by Jack Maloney on 1/9/19.
//

import Foundation
import CommandLineKit

#if os(Linux)
let EX_USAGE: Int32 = 64 // swiftlint:disable:this identifier_name
#endif

let cli = CommandLineKit.CommandLine()

let pathOption = StringOption(shortFlag: "f", longFlag: "file", required: true,
                                 helpMessage: "Path to the input file.")
let libOption = StringOption(shortFlag: "l", longFlag: "lib", required: true,
                              helpMessage: "Path to the library.")
cli.addOptions(pathOption, libOption)

do {
    try cli.parse()
} catch {
    cli.printUsage(error)
    exit(EX_USAGE)
}

// print(libOption.value!)
// print(pathOption.value!)

// var libPath = URL(fileURLWithPath: libOption.value!)
/*
let lib = Library(atPath: libOption.value!)
let hash = lib.addData(try! Data(contentsOf: URL(fileURLWithPath: pathOption.value!)))!.hash
print(hash)
print(String(data: lib.getObject(hash)!.data, encoding: .utf8)!)
*/

let lib = Library(atPath: libOption.value!)
let hash = lib.addData(try! Data(contentsOf: URL(fileURLWithPath: pathOption.value!)))!.hash
print(hash)


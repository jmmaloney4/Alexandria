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
cli.addOptions(pathOption)

do {
    try cli.parse()
} catch {
    cli.printUsage(error)
    exit(EX_USAGE)
}

print(pathOption.value!)

let opt = Object(withPath: pathOption.value!)


//
//  Error.swift
//  Alexandria
//
//  Created by Jack Maloney on 1/15/19.
//

import Foundation

enum AlexandriaError: Error {
    typealias RawValue = Int
    
    case fileDoesNotExist(String, Bool)
}

func handleError(_ error: Error) {
    
}

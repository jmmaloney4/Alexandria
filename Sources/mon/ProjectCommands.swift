//
//  ProjectCommands.swift
//  mon
//
//  Created by Jack Maloney on 1/20/19.
//

import Foundation
import Pergamon
import SwiftCLI

class ProjectCommandGroup: CommandGroup {
    var name = "project"
    var shortDescription = "Commands that manipulate projects"
    var children: [Routable] = []
}

class CreateProject: Command {
    var name = "create"
    
    func execute() throws {
        
    }
}

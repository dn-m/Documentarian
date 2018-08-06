//
//  Git.swift
//  Documentarian
//
//  Created by James Bean on 8/6/18.
//

import SwiftShell

func commitUpdates(for package: Package, with token: String) throws {
    try runAndPrint(bash: "git -c user.name='jsbean' -c user.email='\(token)' commit -am 'Update documentation for the \(package.name) package'")
}

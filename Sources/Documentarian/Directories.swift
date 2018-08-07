//
//  Paths.swift
//  Documentarian
//
//  Created by James Bean on 8/6/18.
//

import SwiftShell
import Files

func prepareDirectories(for package: Package, in directoryPath: String) throws {
    print("Preparing directory structure for the documentation of the \(package.name) package...")
    let packagePath = path(for: package, from: directoryPath)
    run(bash: "rm -rf \(packagePath)")
    run(bash: "mkdir -p \(packagePath)")
    try package.products.forEach { module in
        try runAndPrint(bash: "mkdir -p \(path(for: module, in: package, from: directoryPath))")
    }
}

func path(for package: Package, from root: String) -> String {
    return "\(root)/Packages/\(package.name)"
}

func path(for module: Product, in package: Package, from root: String) -> String {
    return "\(path(for: package, from: root))/Modules/\(module.name)"
}

//
//  Paths.swift
//  Documentarian
//
//  Created by James Bean on 8/6/18.
//

import SwiftShell

func prepareDirectories(for package: Package, in directoryPath: String) throws {
    run(bash: "rm -rf \(directoryPath)/Packages\(package.name)/*")
    package.products.forEach { module in
        run(bash: "mkdir -p \(path(for: module, in: package, from: directoryPath))")
    }
}

func path(for package: Package, from root: String) -> String {
    return "\(root)/Packages/\(package.name)"
}

func path(for module: Product, in package: Package, from root: String) -> String {
    return "\(path(for: package, from: root))/Modules/\(module.name)"
}

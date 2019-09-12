//
//  Jazzy.swift
//  Documentarian
//
//  Created by James Bean on 8/6/18.
//

import SwiftShell

func installJazzy() throws {
    print("Installing jazzy...")
    try runAndPrint(bash: "sudo gem install jazzy")
}

func runJazzy(for module: Product, outputDirectory: String) -> String {
    print("Running jazzy...")
    return """
    jazzy \\
    --author dn-m \\
    --author-url https://dn-m.github.io \\
    --module \(module.name) \\
    --sourcekitten-sourcefile \(module.name).json \\
    --config Sources/\(module.name)/Documentation/.jazzy.yaml \\
    --output \(outputDirectory) \\
    --root-url https://dn-m.github.io \\
    --theme fullwidth \\
    --readme Sources/\(module.name)/README.md \\
    --abstract Sources/\(module.name)/Documentation/* \\
    --disable-search \\
    --clean \\
    """
}

func cleanUpJazzyArtifacts(for module: Product) -> String {
    return "rm \(module.name).json"
}

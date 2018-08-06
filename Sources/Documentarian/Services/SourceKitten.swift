//
//  SourceKitten.swift
//  Documentarian
//
//  Created by James Bean on 8/6/18.
//

import SwiftShell
import Files

func fetchAndBuildSourceKitten() throws {
    if !Folder.current.containsSubfolder(named: "SourceKitten") {
        try runAndPrint(bash: "git clone https://github.com/jpsim/SourceKitten")
    }
    SwiftShell.main.currentdirectory = "SourceKitten"
    try runAndPrint(bash: "rm -f .swift-version")
    print("Building SourceKitten...")
    try runAndPrint(bash: "swift build")
    print("Done building SourceKitten")
    SwiftShell.main.currentdirectory = ".."
}

func runSourceKitten(for module: Product) -> String {
    return "SourceKitten/.build/debug/sourcekitten doc --spm-module \(module.name) > \(module.name).json"
}

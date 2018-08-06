//
//  Github.swift
//  Documentarian
//
//  Created by James Bean on 8/6/18.
//

import SwiftShell
import Files

func pullSiteRepo() throws {
    print("Pulling the dn-m.github.io site repository...")
    guard let token = GITHUB_TOKEN else { throw Error.personalAccessTokenNotFound }
    if !Folder.current.containsSubfolder(named: "dn-m.github.io") {
        try runAndPrint(bash: "git clone https://jsbean:\(token)@github.com/dn-m/dn-m.github.io")
    }
    SwiftShell.main.currentdirectory = "dn-m.github.io"
    try runAndPrint(bash: "git pull origin master")
    SwiftShell.main.currentdirectory = ".."
}

func pushUpdates() throws {
    print("Pushing updates to the dn-m.github.io site repository...")
    guard let token = GITHUB_TOKEN else { throw Error.personalAccessTokenNotFound }
    print("We have a token (length: \(token.count), about to push up to Github!")
    try runAndPrint(bash: "git push -f https://jsbean:\(token)@github.com/dn-m/dn-m.github.io master")
}

func pushSiteRepo(for package: Package) throws {
    SwiftShell.main.currentdirectory = "dn-m.github.io"
    try commitUpdates(for: package)
    try pushUpdates()
    SwiftShell.main.currentdirectory = ".."
}

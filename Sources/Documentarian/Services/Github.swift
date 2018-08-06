//
//  Github.swift
//  Documentarian
//
//  Created by James Bean on 8/6/18.
//

import SwiftShell
import Files

func pullSiteRepo(with token: String) throws {
    print("Pulling the dn-m.github.io site repository...")
    if !Folder.current.containsSubfolder(named: "dn-m.github.io") {
        try runAndPrint(bash: "git clone https://jsbean:\(token)@github.com/dn-m/dn-m.github.io")
    }
    SwiftShell.main.currentdirectory = "dn-m.github.io"
    try runAndPrint(bash: "git pull origin master")
    SwiftShell.main.currentdirectory = ".."
}

func pushUpdates(with token: String) throws {
    print("Pushing updates to the dn-m.github.io site repository...")
    try runAndPrint(bash: "git push -f https://jsbean:\(token)@github.com/dn-m/dn-m.github.io master")
}

func pushSiteRepo(for package: Package, with token: String) throws {
    SwiftShell.main.currentdirectory = "dn-m.github.io"
    try commitUpdates(for: package, with: token)
    try pushUpdates(with: token)
    SwiftShell.main.currentdirectory = ".."
}

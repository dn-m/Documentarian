//
//  SwiftPackageManager.swift
//  Documentarian
//
//  Created by James Bean on 8/6/18.
//

import Foundation
import SwiftShell

/// - Returns: A `Package` for the given Swift Package repository.
func decodePackage() throws -> Package {
    let data = run(bash: "swift package dump-package").stdout.data(using: .utf8)!
    let decoder = JSONDecoder()
    return try decoder.decode(Package.self, from: data)
}

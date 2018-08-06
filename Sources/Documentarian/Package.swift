//
//  Package.swift
//  Documentarian
//
//  Created by James Bean on 8/5/18.
//

/// Very streamlined model of a Swift Package.
struct Package: Decodable {
    let name: String
    let products: [Product]
}

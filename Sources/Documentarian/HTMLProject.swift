//
//  HTMLProject.swift
//  Documentarian
//
//  Created by James Bean on 8/5/18.
//

import Files

func navigationGroup(for package: Package) -> String {
    return """
    <li class="nav-group-name" id="\(package.name)">
    <a href="Packages/\(package.name)/index.html" class="nav-group-name-link">\(package.name)</span>
    \(moduleNavigationItems(for: package, in: "Packages/\(package.name)/Modules"))
    </li>
    """
}

func navigationGroups(for packages: [Package]) -> String {
    return packages.map(navigationGroup).joined(separator: "\n")
}

func navigation(for packages: [Package]) -> String {
    return """
    <nav class="navigation">
    <ul class="nav-groups">
    \(navigationGroups(for: packages))
    </ul>
    </nav>
    """
}

func abstract() -> String {
    return """
    <article class="main-content">
    <section class="section">
    <div class="section-content">
    The is the documentation of the dn-m project.
    </div>
    </section>
    </article>
    """
}

func content(for packages: [Package]) -> String {
    return """
    <div class="content-wrapper">
    \(navigation(for: packages))
    \(abstract())
    </div>
    """
}

func breadcrumbs(assetsPath: String) -> String {
    return """
    <p class="breadcrumbs">
    <a class="breadcrumb" href="https://dn-m.github.io">dn-m</a>
    <img class="carat" src="\(assetsPath)/img/carat.png">
    dn-m
    </p>
    """
}

func body(for packages: [Package], assetsPath: String) -> String {
    return """
    <body>
    <a title="dn-m | Documentation Home"></a>
    \(header())
    \(breadcrumbs(assetsPath: assetsPath))
    \(content(for: packages))
    \(footer())
    </body>
    """
}

func index(for packages: [Package], assetsPath: String) -> String {
    return html(
        head: head(title: "dn-m", assetsPath: assetsPath),
        body: body(for: packages, assetsPath: assetsPath)
    )
}

func packages(from directoryPath: String) throws -> [Package] {
    return try Folder.init(path: "\(directoryPath)/Packages").subfolders.map { packageDir in
        Package(
            name: packageDir.name,
            products: try packageDir.subfolder(named: "Modules").subfolders.map {
                Product(name: $0.name)
            }
        )
    }
}

/// Generates the documentation for the entire dn-m project.
func generateHome(in directoryPath: String, assetsPath: String) throws {
    let file = try File(path: "\(directoryPath)/index.html")
    try file.delete()
    try file.write(string: index(for: try packages(from: directoryPath), assetsPath: assetsPath))
}

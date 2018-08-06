//
//  HTMLPackage.swift
//  Documentarian
//
//  Created by James Bean on 8/5/18.
//

import SwiftShell

func breadcrumbs(for package: Package, assetsPath: String) -> String {
    return """
    <p class="breadcrumbs">
    <a class="breadcrumb" href="https://dn-m.github.io">dn-m</a>
    <img class="carat" src="\(assetsPath)/img/carat.png">
    \(package.name)
    </p>
    """
}

/// - Returns: The navigation item for the given `module`.
func moduleNavigationItem(for module: Product, in directoryPath: String) -> String {
    return """
    <li class="nav-group-task">
    <a class="nav-group-task-link" href="\(directoryPath)/\(module.name)/index.html">\(module.name)</a>
    </li>
    """
}

/// - Returns: All of the navigation items for a `package`.
func moduleNavigationItems(for package: Package, in directoryPath: String) -> String {
    return """
    <ul class="nav-group-tasks">
    \(package.products.map { moduleNavigationItem(for: $0, in: directoryPath) }.joined(separator: "\n"))
    </ul>
    """
}

/// - Returns: Navigation group with the given `name` or the given `package`.
func navigationGroup(with name: String, for package: Package) -> String {
    return """
    <li class="nav-group-name" id="\(name)">
    <span class="nav-group-name-link">\(name)</span>
    \(moduleNavigationItems(for: package, in: "Modules"))
    </li>
    """
}

/// - Returns: The navigation for the given `package`.
func navigation(for package: Package) -> String {
    return """
    <nav class="navigation">
    <ul class="nav-groups">
    \(navigationGroup(with: "Modules", for: package))
    </ul>
    </nav>
    """
}

/// - Returns: The article `main-content` for the given `package`.
func abstract(for package: Package) -> String {
    return """
    <article class="main-content">
    <section class="section">
    <div class="section-content">
    \(run("redcarpet", "README.md").stdout)
    </div>
    </section>
    </article>
    """
}

/// - Returns: The content wrapper div, including the navigation pane and frontmatter.
func content(for package: Package) -> String {
    return """
    <div class="content-wrapper">
    \(navigation(for: package))
    \(abstract(for: package))
    </div>
    """
}

/// - Returns: The `body` section of the `index.html` for the given `package`.
func body(for package: Package, assetsPath: String) -> String {
    return """
    <body>
    <a title="dn-m | \(package.name)"></a>
    \(header())
    \(breadcrumbs(for: package, assetsPath: assetsPath))
    \(content(for: package))
    \(footer())
    </body>
    """
}

/// - Returns: The `index.html` contents for the given `package`.
func index(for package: Package, assetsPath: String) -> String {
    return html(
        head: head(title: "dn-m | \(package.name)", assetsPath: assetsPath),
        body: body(for: package, assetsPath: assetsPath)
    )
}

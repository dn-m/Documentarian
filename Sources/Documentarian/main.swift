import Foundation
import SwiftShell

/// Very streamlined model of a Swift Package.
struct Package: Decodable {
    let name: String
    let products: [Product]
}

/// Very streamlined model of a Swift Product (in this case, we only case about Swift Modules).
struct Product: Decodable {
    let name: String
}

/// - Returns: A `Package` for the given Swift Package repository.
func decodePackage() throws -> Package {
    let data = run(bash: "swift package dump-package").stdout.data(using: .utf8)!
    let decoder = JSONDecoder()
    return try decoder.decode(Package.self, from: data)
}

/// Generates documentation for all of the given `modules` in the given `package`.
func generateDocs(for modules: [Product], in package: Package) throws {
    try modules.forEach { try generateDocs(for: $0, in: package) }
}

func runSourceKitten(for module: Product) -> String {
    return "SourceKitten/.build/debug/sourcekitten doc --spm-module \(module.name) > \(module.name).json"
}

func runJazzy(for module: Product) -> String {
    return """
    jazzy \\
    --sourcekitten-sourcefile \(module.name).json \\
    --config ./Sources/\(module.name)/Documentation/.jazzy.yaml \\
    --output Documentation/Packages/\(module.name) \\
    --theme fullwidth \\
    --abstract ./Sources/\(module.name)/Documentation/*
    """
}

func cleanUpJazzyArtifacts(for module: Product) -> String {
    return "rm \(module.name).json"
}

/// Generates documentation for the given `module` in the given `package`.
func generateDocs(for module: Product, in package: Package) throws {
    print("Generating documentation for the \(module.name) module")
    run(bash: runSourceKitten(for: module))
    run(bash: runJazzy(for: module))
    run(bash: cleanUpJazzyArtifacts(for: module))
}

func styleSheet(at path: String) -> String {
    return """
    <link rel="stylesheet" type="text/css" href="\(path)/css/jazzy.css">
    <link rel="stylesheet" type="text/css" href="\(path)/css/highlight.css">
    """
}

/// - Returns: The scripts section of the `<head>` section for the `index.html`.
func scripts(at path: String) -> String {
    return """
    <script src="\(path)/js/jquery.min.js" defer></script>
    <script src="\(path)/js/jazzy.js" defer></script>
    """
}

/// - Returns: <head> section of `index.html`.
func head(title: String, assetsPath: String) -> String {
    return """
    <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>\(title)</title>
        \(styleSheet(at: assetsPath))
        <meta charset="utf-8">
        \(scripts(at: assetsPath))
    </head>
    """
}

/// - Returns: <header> section of `index.html`.
func header() -> String {
    return """
    <header class="header">
      <p class="header-col header-col--primary">
        <a class="header-link" href="index.html">
          dn-m Docs
        </a>
      </p>
      <p class="header-col header-col--secondary">
        <a class="header-link" href="https://github.com/dn-m/">
          <img class="header-icon" src="build/img/gh.png">
          View on GitHub
        </a>
      </p>
    </header>
    """
}

func breadcrumbs(for package: Package) -> String {
    return """
    <p class="breadcrumbs">
        <a class="breadcrumb" href="https://dn-m.github.io">dn-m</a>
        <img class="carat" src="../Documentarian/img/carat.png"> \(package.name)
    </p>
    """
}

/// - Returns: The navigation item for the given `module`.
func moduleNavigationItem(for module: Product) -> String {
    return """
    <li class="nav-group-task">
        <a class="nav-group-task-link" href="Packages/\(module.name)/index.html">\(module.name)</a>
    </li>
    """
}

/// - Returns: All of the navigation items for a `package`.
func moduleNavigationItems(for package: Package) -> String {
    return """
    <ul class="nav-group-tasks">
        \(package.products.map(moduleNavigationItem).joined(separator: "\n"))
    </ul>
    """
}

/// - Returns: Navigation group with the given `name` or the given `package`.
func navigationGroup(with name: String, for package: Package) -> String {
    return """
    <li class="nav-group-name" id="\(name)">
    <span class="nav-group-name-link">\(name)</span>
        \(moduleNavigationItems(for: package))
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

/// - Returns: The `<footer>` for the `index.html`.
func footer() -> String {
    return """
    <section class="footer">
        <p>© 2018 <a class="link" href="https://github.com/dn-m" target="_blank" rel="external">dn-m</a>. All rights reserved.</p>
    </section>
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
func body(for package: Package) -> String {
    return """
    <body>
        <a title="dn-m | \(package.name)"></a>
        \(header())
        \(breadcrumbs(for: package))
        \(content(for: package))
    \(footer())
    </body>
    """
}

/// - Returns: The `index.html` contents for the given `package`.
func index(for package: Package) throws -> String {
    return html(
        head: head(title: "dn-m", assetsPath: "../Documentarian"),
        body: body(for: package)
    )
}

/// - Returns: The html required for a site with the given `head`, and `body` elements.
func html(head: String, body: String) -> String {
    return """
    <!DOCTYPE html>
    <html lang="en">
        \(head)
        \(body)
    </html>
    """
}

/// - Returns: The `index.html` for `dn-m.github.io`.
func home() -> String {
    // header
    func content() -> String {
        return "<p>Home</p>"
    }
    return head(title: "dn-m | Home", assetsPath: "../Documentarian") + content()
}

/// Uses `jazzy` to generate the website for the given `package.`
func generateSite(for package: Package, at outputPath: String) throws {
    print("Generating site for \(package.name)")
    try runAndPrint(bash: "rm -f \(outputPath)/index.html")
    let filePath = outputPath.appending("/index.html")
    let file = try open(forWriting: filePath)
    file.write(try index(for: package))
    file.close()
}

func generateHome() throws {
    print("Generating home")
    try runAndPrint(bash: "rm -f index.html")
    let file = try open(forWriting: "index.html")
    file.write(home())
    file.close()
}

func pullDocSite() throws {
    print("Cloning dn-m.github.io source")
    try runAndPrint(bash: "git clone https://github.com/dn-m/dn-m.github.io")
}

func buildSourceKittenIfNecessary() -> String {
    return "if cd SourceKitten; then git pull; else git clone https://github.com/jpsim/SourceKitten; fi"
}

func fetchAndBuildSourceKitten() throws {
    print("Fetching SourceKitten...")
    try runAndPrint(bash: "rm -f .swift-version")
    try runAndPrint(bash: buildSourceKittenIfNecessary())
    run(bash: "cd SourceKitten")
    print("Building SourceKitten...")
    try runAndPrint(bash: "swift build --package-path SourceKitten")
    run(bash: "cd ..")
}

enum Error: Swift.Error {
    case invalidModuleName(String)
}

/// - Returns: The modules from the given list of `potentialModuleNames` if they match up with
/// actual module names in the given `package`.
func validModules <C> (from potentialModuleNames: C, in package: Package) throws -> [Product]
    where C: Collection, C.Element == String
{
    // If no module names are given, build all modules
    guard !potentialModuleNames.isEmpty else { return package.products }
    let actualModuleNames = package.products.map { $0.name }
    // If any of the given potential module names are not found in the given `package`, throw error
    for potentialModuleName in potentialModuleNames {
        guard actualModuleNames.contains(potentialModuleName) else {
            throw Error.invalidModuleName(potentialModuleName)
        }
    }
    return potentialModuleNames.map(Product.init)
}

/// Generates documentation for the local Swift Package. If you only want to generate the
/// documentation for a given subset of modules, you can specify them by their name as arguments.
///
/// Otherwise, documentation for all packages will be generated.
func main() {
    do {
        let package = try decodePackage()
        let arguments = CommandLine.arguments.dropFirst()
        let products = try validModules(from: arguments, in: package)
        try fetchAndBuildSourceKitten()
        try pullDocSite()
        try generateDocs(for: products, in: package)
        try generateSite(for: package, at: "Documentation")
        try generateHome()
    } catch {
        print(error)
    }
}

main()

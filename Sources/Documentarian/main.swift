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
    let data = run("swift", "package", "dump-package").stdout.data(using: .utf8)!
    let decoder = JSONDecoder()
    return try decoder.decode(Package.self, from: data)
}

/// Generates documentation for all of the given `modules` in the given `package`.
func generateDocs(for modules: [Product], in package: Package) throws {
    try modules.forEach { try generateDocs(for: $0, in: package) }
}

/// Generates documentation for the given `module` in the given `package`.
func generateDocs(for module: Product, in package: Package) throws {
    print("Generating documentation for the \(module.name) module")
    run(bash: "SourceKitten/.build/debug/sourcekitten doc --spm-module \(module.name) > \(module.name).json")
    run(bash: """
        jazzy \\
        -s \(module.name).json \\
        --config ./Sources/\(module.name)/Documentation/.jazzy.yaml \\
        --output Documentation/Packages/\(module.name) \\
        --theme fullwidth \\
        --abstract ./Sources/\(module.name)/Documentation/*
        """
    )
    run(bash: "rm \(module.name).json")
}

func generateSite(for package: Package) throws {
    print("Generating site for \(package.name)")
    let fakeSite = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>dn-m</title>
        <link rel="stylesheet" type="text/css" href="build/css/jazzy.css">
        <link rel="stylesheet" type="text/css" href="build/css/highlight.css">
        <meta charset="utf-8">
        <script src="Documentarian/js/jquery.min.js" defer></script>
        <script src="Documentarian/js/jazzy.js" defer></script>
    </head>
    <body>
    <p>Hello, world!</p>
    </body>
    </html>
    """
    run(bash: "\(fakeSite) > Documentation/index.html")
}

func pullDocSite() throws {
    #warning("Reintroduce pulling doc site when deployed")
    //try runAndPrint(bash: "git clone https://github.com/dn-m/dn-m.github.io")
}

func fetchAndBuildSourceKitten() throws {
    print("Fetching SourceKitten...")
    try runAndPrint(bash: "rm -f .swift-version")
    try runAndPrint(bash: "if [ ! -d 'SourceKitten' ]; then git clone https://github.com/jpsim/SourceKitten fi")
    run(bash: "cd SourceKitten")
    print("Building SourceKitten...")
    try runAndPrint(bash: "swift build --package-path SourceKitten")
    run(bash: "cd ..")
}

enum Error: Swift.Error {
    case invalidModuleName(String)
}

func validProducts <C> (from arguments: C, in package: Package) throws -> [Product]
    where C: Collection, C.Element == String
{
    guard !arguments.isEmpty else { return package.products }
    let actualModuleNames = package.products.map { $0.name }
    for potentialModuleName in arguments {
        guard actualModuleNames.contains(potentialModuleName) else {
            throw Error.invalidModuleName(potentialModuleName)
        }
    }
    return arguments.map(Product.init)
}

/// Generates documentation for the local Swift Package. If you only want to generate the
/// documentation for a given subset of modules, you can specify them by their name as arguments.
///
/// Otherwise, documentation for all packages will be generated.
func main() {

    do {
        let package = try decodePackage()
        let arguments = CommandLine.arguments.dropFirst()
        let products = try validProducts(from: arguments, in: package)
        try fetchAndBuildSourceKitten()
        try generateDocs(for: products, in: package)
        try generateSite(for: package)
        try pullDocSite()
    } catch {
        print(error)
    }
}

main()

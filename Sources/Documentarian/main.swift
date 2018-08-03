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
        --output Documentation/\(module.name) \\
        --theme fullwidth \\
        --abstract ./Sources/\(module.name)/Documentation/*
        """
    )
}

func generateSite(for package: Package) throws {
    print("Generating site for \(package.name)")
}

func pullDocSite() throws {
    try runAndPrint(bash: "git clone https://github.com/dn-m/dn-m.github.io")
}

func fetchAndBuildSourceKitten() {
    print("Fetching SourceKitten...")
    run(bash: "rm -rf SourceKitten")
    run(bash: "rm -f .swift-version")
    run(bash: "git clone https://github.com/jpsim/SourceKitten && cd SourceKitten")
    print("Building SourceKitten...")
    run(bash: "swift build --package-path SourceKitten")
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
        fetchAndBuildSourceKitten()
        try generateDocs(for: products, in: package)
        try generateSite(for: package)
        try pullDocSite()
    } catch {
        print(error)
    }
}

main()

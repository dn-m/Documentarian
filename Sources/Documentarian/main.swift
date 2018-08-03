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
    print("generate docs for \(module.name) in \(package.name)")

    // Assumes SourceKitten has been installed

//    let json = run("SourceKitten/.build/debug/sourcekitten", "doc", "--spm-module", module.name)
//    print("JSON:")
//    print(json.stdout)
    try runAndPrint(bash: "SourceKitten/.build/debug/sourcekitten doc --spm-module \(module.name) > \(module.name).json")
    try runAndPrint(bash: "jazzy -s \(module.name).json --config ./Sources/\(module.name)/Documentation/.jazzy.yaml --output Sources/\(module.name)/Documentation/Output --theme fullwidth --abstract ./Sources/\(module.name)/Documentation")
}

/// Generates documentation for the local Swift Package. If you only want to generate the
/// documentation for a given subset of modules, you can specify them by their name as arguments.
///
/// Otherwise, documentation for all packages will be generated.
func main() {

    do {

        // Clone and build SourceKittn
        // TODO: Move out into function, only perform if names are valid (see below)
        run(bash: "git clone https://github.com/jpsim/SourceKitten && cd SourceKitten")
        run(bash: "rm -f .swift-version")
        run(bash: "swift build --package-path SourceKitten")
        run(bash: "cd ..")

        let package = try decodePackage()
        let arguments = CommandLine.arguments.dropFirst()

        // If no arguments are given, generate documentation for all modules in package
        if arguments.isEmpty {
            try generateDocs(for: package.products, in: package)
        } else {
            // If any of the names are bad, bail.
            for potentialModuleName in arguments {
                guard package.products.map({ $0.name }).contains(potentialModuleName) else {
                    print("No such module \(potentialModuleName)")
                    return
                }
            }
            // Generate documentation for the modules specified
            try generateDocs(for: arguments.map(Product.init), in: package)
        }
    } catch {
        print(error)
    }
}

main()

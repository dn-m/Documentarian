import Foundation
import SwiftShell
import Files

/// - Returns: A `Package` for the given Swift Package repository.
func decodePackage() throws -> Package {
    let data = run(bash: "swift package dump-package").stdout.data(using: .utf8)!
    let decoder = JSONDecoder()
    return try decoder.decode(Package.self, from: data)
}

func runSourceKitten(for module: Product) -> String {
    return "SourceKitten/.build/debug/sourcekitten doc --spm-module \(module.name) > \(module.name).json"
}

func runJazzy(for module: Product, outputDirectory: String) -> String {
    return """
    jazzy \\
    --sourcekitten-sourcefile \(module.name).json \\
    --config ./Sources/\(module.name)/Documentation/.jazzy.yaml \\
    --output \(outputDirectory) \\
    --theme fullwidth \\
    --abstract ./Sources/\(module.name)/Documentation/* \\
    --disable-search
    """
}

func cleanUpJazzyArtifacts(for module: Product) -> String {
    return "rm \(module.name).json"
}

/// Generates documentation for the given `module` in the given `package`.
func generateDocs(for module: Product, in packageDirectory: String) throws {
    let moduleDirectory = "\(packageDirectory)/Modules/\(module.name)"
    print("Generating documentation for the \(module.name) module in \(moduleDirectory)...")
    run(bash: runSourceKitten(for: module))
    try runAndPrint(bash: runJazzy(for: module, outputDirectory: moduleDirectory))
    run(bash: cleanUpJazzyArtifacts(for: module))
}

func generateHomeIndex(for package: Package, in directoryPath: String, assetsPath: String) throws {
    let file = try open(forWriting: "\(directoryPath)/index.html")
    file.write(index(for: package, assetsPath: assetsPath))
    file.close()
}

/// Generates documentation for all of the given `modules` in the given `package`, and creates a
/// home `index.html` for the package.
func generateDocs(for package: Package, in directoryPath: String, assetsPath: String) throws {
    try generateHomeIndex(for: package, in: directoryPath, assetsPath: assetsPath)
    try package.products.forEach { try generateDocs(for: $0, in: "\(directoryPath)") }
}
/// Generates the documentation for the entire dn-m project.
func generateHome(in directoryPath: String, assetsPath: String) throws {
    print("Generating home in \(directoryPath)")
    let indexPath = "\(directoryPath)/index.html"
    try runAndPrint(bash: "rm -f \(indexPath)")
    let file = try open(forWriting: "\(indexPath)")
    file.write(index(for: try packages(from: directoryPath), assetsPath: assetsPath))
    file.close()
}

func cloneSiteIfNecessary() -> String {
    return "if cd dn-m.github.io; then git pull origin master; else git clone https://github.com/dn-m/dn-m.github.io; fi"
}

func pullDocSite() throws {
    print("Cloning and updating dn-m.github.io source")
    try runAndPrint(bash: cloneSiteIfNecessary())
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

func prepareDirectories(for package: Package, in directoryPath: String) throws {
    run(bash: "rm -rf \(directoryPath)/Packages\(package.name)/*")
    package.products.forEach { module in
        run(bash: "mkdir -p \(path(for: module, in: package, from: directoryPath))")
    }
}

func path(for package: Package, from root: String) -> String {
    return "\(root)/Packages/\(package.name)"
}

func path(for module: Product, in package: Package, from root: String) -> String {
    return "\(path(for: package, from: root))/Modules/\(module.name)"
}

enum Error: Swift.Error {
    case invalidModuleName(String)
}

/// Generates documentation for the local Swift Package.
func main() {
    do {
        let package = try decodePackage()
        // Clone SourceKitten if necessary, which scrapes documentable info from source code
        try fetchAndBuildSourceKitten()
        // Clone / update the dn-m/dn-m.github.io repo
        try pullDocSite()
        // Create the directory infrastructure for the documentation of the package we are visiting
        try prepareDirectories(for: package, in: "dn-m.github.io")
        // Generate the documentation for package we are visiting
        try generateDocs(
            for: package,
            in: "dn-m.github.io/Packages/\(package.name)",
            assetsPath: "../../../assets"
        )
        // Update the home page to reflect the changes.
        try generateHome(in: "dn-m.github.io", assetsPath: "../assets")

        // Attempt to push updates to github repo. This will require auth.
        SwiftShell.main.currentdirectory = "dn-m.github.io"
        try runAndPrint(bash: """
        if [ -n $GITHUB_TOKEN ]; then
            git -c user.name='travis' -c user.email='travis' commit -m init
            git commit -am 'Update documentation for the \(package.name) package'
            git push -f -q https://jsbean:$GITHUB_TOKEN@github.com/dn-m/\(package.name) master &2>/dev/null
        fi
        """)
        SwiftShell.main.currentdirectory = ".."
    } catch {
        print(error)
    }
}

main()

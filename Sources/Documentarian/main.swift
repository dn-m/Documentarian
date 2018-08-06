import Foundation
import SwiftShell
import Files

let GITHUB_TOKEN = ProcessInfo.processInfo.environment["GITHUB_TOKEN"]!

/// - Returns: A `Package` for the given Swift Package repository.
func decodePackage() throws -> Package {
    let data = run(bash: "swift package dump-package").stdout.data(using: .utf8)!
    let decoder = JSONDecoder()
    return try decoder.decode(Package.self, from: data)
}

func runSourceKitten(for module: Product) -> String {
    return "SourceKitten/.build/debug/sourcekitten doc --spm-module \(module.name) > \(module.name).json"
}

func installJazzy() throws {
    print("attempting to install jazzy: \(Folder.current)")
    try runAndPrint(bash: "sudo gem install jazzy")
}

func runJazzy(for module: Product, outputDirectory: String) -> String {
    return """
    jazzy \\
    --sourcekitten-sourcefile \(module.name).json \\
    --config ./Sources/\(module.name)/Documentation/.jazzy.yaml \\
    --output \(outputDirectory) \\
    --theme fullwidth \\
    --abstract ./Sources/\(module.name)/Documentation/* \\
    --disable-search \\
    --clean \\
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
    let file = try File(path: "\(directoryPath)/index.html")
    try file.delete()
    try file.write(string: index(for: package, assetsPath: assetsPath))
}

/// Generates documentation for all of the given `modules` in the given `package`, and creates a
/// home `index.html` for the package.
func generateDocs(for package: Package, in directoryPath: String, assetsPath: String) throws {
    try generateHomeIndex(for: package, in: directoryPath, assetsPath: assetsPath)
    try package.products.forEach { try generateDocs(for: $0, in: "\(directoryPath)") }
}
/// Generates the documentation for the entire dn-m project.
func generateHome(in directoryPath: String, assetsPath: String) throws {
    let file = try File(path: "\(directoryPath)/index.html")
    try file.delete()
    try file.write(string: index(for: try packages(from: directoryPath), assetsPath: assetsPath))
}

func fetchAndBuildSourceKitten() throws {
    if !Folder.current.containsSubfolder(named: "SourceKitten") {
        try runAndPrint(bash: "git clone https://github.com/jpsim/SourceKitten")
    }
    SwiftShell.main.currentdirectory = "SourceKitten"
    try runAndPrint(bash: "rm -f .swift-version")
    print("Building SourceKitten...")
    try runAndPrint(bash: "swift build")
    print("Done building SourceKitten")
    SwiftShell.main.currentdirectory = ".."
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

func pullSiteRepo() throws {
    if !Folder.current.containsSubfolder(named: "dn-m.github.io") {
        try runAndPrint(bash: "git clone https://jsbean:\(GITHUB_TOKEN)@github.com/dn-m/dn-m.github.io")
    }
    SwiftShell.main.currentdirectory = "dn-m.github.io"
    try runAndPrint(bash: "git pull origin master")
    SwiftShell.main.currentdirectory = ".."
    print("pulled site repo")
}

func commitUpdates(for package: Package) throws {
    try runAndPrint(bash: """
    git -c user.name='jsbean' -c user.email='\(GITHUB_TOKEN)' commit -am 'Update documentation for the \(package.name) package'
    """)
}

func pushUpdates() throws {
    print("Pushing updates to the `github.com/dn-m/dn-m.github.io` repository...")
    try runAndPrint(bash: """
    if [ -n $GITHUB_TOKEN ]; then
    echo Be there a github token!
    git push -f -q https://jsbean:\(GITHUB_TOKEN)@github.com/dn-m/dn-m.github.io master &2>/dev/null
    fi
    """)
}

func pushSiteRepo(for package: Package) throws {
    SwiftShell.main.currentdirectory = "dn-m.github.io"
    try commitUpdates(for: package)
    try pushUpdates()
    SwiftShell.main.currentdirectory = ".."
}

enum Error: Swift.Error {
    case invalidModuleName(String)
}

/// Generates documentation for the local Swift Package.
func main() throws {
    // Infer a model of the package from the `Package.swift` manifest file.
    let package = try decodePackage()
    // Clone `SourceKitten` if necessary, which scrapes documentation from Swift source code.
    try fetchAndBuildSourceKitten()
    // Install `jazzy`, to be used to generate documentation from `SourceKitten` artifacts.
    try installJazzy()
    // Clone / update the dn-m/dn-m.github.io repo
    try pullSiteRepo()
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
    try pushSiteRepo(for: package)
}

try main()

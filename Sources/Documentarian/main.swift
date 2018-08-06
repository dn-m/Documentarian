import Foundation
import SwiftShell
import Files

enum Error: Swift.Error {
    case invalidModuleName(String)
    case personalAccessTokenNotFound
}

/// Generates documentation for the local Swift Package.
func main() throws {
    // Infer a model of the package from the `Package.swift` manifest file.
    let package = try decodePackage()
    // Clone `SourceKitten` if necessary, which scrapes documentation from Swift source code.
    try fetchAndBuildSourceKitten()
    // Install `jazzy`, to be used to generate documentation from `SourceKitten` artifacts.
    try installJazzy()
    // Don't even bother if there is no Github personal access token.
    guard let token = ProcessInfo.processInfo.environment["GITHUB_TOKEN"] else {
        throw Error.personalAccessTokenNotFound
    }
    // Clone / update the dn-m/dn-m.github.io repo
    try pullSiteRepo(with: token)
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
    try pushSiteRepo(for: package, with: token)
    print("Successfully pushed site to GitHub!")
}

do {
    try main()
} catch {
    print(error)
}

import Foundation
import SwiftShell
import Files

// TODO: Consider only doing this on a release (tag).
func ensurePushingOnMasterBranch(env: [String: String]) throws {
    // Bail if Travis CI environment variables are not found
    guard let branch = env["TRAVIS_BRANCH"] else {
        throw Error.environmentVariableNotFound("TRAVIS_BRANCH")
    }
    // Only generate documentation when pushing to master branch
    guard branch == "master" else {
        throw Error.notOnMasterBranch(branch)
    }
    // Only generate documentation when pushing, not pulling
    guard let isPullRequest = env["TRAVIS_PULL_REQUEST"], isPullRequest == "false" else {
        throw Error.notPush
    }
}

func ensureOperatingSystemIsMacOS() throws {
    // Only generate documentation if we are testing on macos, as to avoid duplicating work
    guard let os = env["TRAVIS_OS_NAME"], os == "osx" else { throw Error.notMacOS }
}

enum Error: Swift.Error {
    case invalidModuleName(String)
    case personalAccessTokenNotFound
    case environmentVariableNotFound(String)
    case notOnMasterBranch(String)
    case notPush
    case notMacOS
}

let env = ProcessInfo.processInfo.environment

/// Generates documentation for the local Swift Package.
func main() throws {
    try ensurePushingOnMasterBranch(env: env)
    try ensureOperatingSystemIsMacOS()
    // Infer a model of the package from the `Package.swift` manifest file.
    let package = try decodePackage()
    // Clone `SourceKitten` if necessary, which scrapes documentation from Swift source code.
    try fetchAndBuildSourceKitten()
    // Install `jazzy`, to be used to generate documentation from `SourceKitten` artifacts.
    try installJazzy()
    // Don't even bother if there is no Github personal access token.
    guard let token = env["GITHUB_TOKEN"] else { throw Error.personalAccessTokenNotFound }
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
}

do {
    try main()
} catch {
    print(error)
}

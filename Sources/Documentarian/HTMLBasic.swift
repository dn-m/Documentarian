//
//  HTMLBasic.swift
//  Documentarian
//
//  Created by James Bean on 8/5/18.
//

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
func header(assetsPath: String) -> String {
    return """
    <header class="header">
    <p class="header-col header-col--primary">
    <a class="header-link" href="index.html">
    dn-m Docs
    </a>
    </p>
    <p class="header-col header-col--secondary">
    <a class="header-link" href="https://github.com/dn-m/">
    <img class="header-icon" src="\(assetsPath)/img/gh.png">
    View on GitHub
    </a>
    </p>
    </header>
    """
}

/// - Returns: The HTML code for stylesheets applicable to the `dn-m` project.
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

/// - Returns: The `<footer>` for the `index.html`.
func footer() -> String {
    return """
    <section class="footer">
    <p>© 2018 <a class="link" href="https://github.com/dn-m" target="_blank" rel="external">dn-m</a>. All rights reserved.</p>
    </section>
    """
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

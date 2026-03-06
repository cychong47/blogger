import Foundation

enum CategoryScanner {
    /// Walks all .md files under contentPath and returns a sorted unique list of categories.
    static func scan(contentPath: String) -> [String] {
        let base = URL(fileURLWithPath: contentPath)
        guard let enumerator = FileManager.default.enumerator(
            at: base,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var categories = Set<String>()
        for case let url as URL in enumerator where url.pathExtension == "md" {
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { continue }
            parseFrontmatterCategories(from: content).forEach { categories.insert($0) }
        }
        return categories.sorted()
    }

    /// Parses the `categories: [...]` line from a markdown frontmatter block.
    static func parseFrontmatterCategories(from content: String) -> [String] {
        guard let range = content.range(
            of: #"(?m)^categories:\s*\[([^\]]*)\]"#,
            options: .regularExpression
        ) else { return [] }

        let match = String(content[range])
        guard let open = match.firstIndex(of: "["),
              let close = match.lastIndex(of: "]") else { return [] }

        let inside = String(match[match.index(after: open)..<close])
        guard !inside.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        return inside.components(separatedBy: ",").compactMap { item in
            let trimmed = item
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            return trimmed.isEmpty ? nil : trimmed
        }
    }
}

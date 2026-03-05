import Foundation

enum MarkdownGenerator {
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func frontmatter(title: String, date: Date) -> String {
        let dateStr = dateFormatter.string(from: date)
        return """
        ---
        title: "\(title)"
        date: \(dateStr)
        draft: false
        ---
        """
    }

    static func imageReference(markdownPath: String) -> String {
        "![](\(markdownPath))"
    }

    static func initialMarkdown(title: String, date: Date, photos: [ExportedPhoto]) -> String {
        var parts: [String] = [frontmatter(title: title, date: date), ""]
        let imageRefs = photos.map { imageReference(markdownPath: $0.markdownPath) }
        parts.append(contentsOf: imageRefs)
        parts.append("")
        parts.append("") // cursor position placeholder
        return parts.joined(separator: "\n")
    }

    static func write(content: String, slug: String, date: Date, settings: AppSettings) throws -> URL {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let monthStr = String(format: "%02d", month)

        let destDir = URL(fileURLWithPath: settings.contentPath)
            .appendingPathComponent("\(year)", isDirectory: true)
            .appendingPathComponent(monthStr, isDirectory: true)

        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        let fileURL = destDir.appendingPathComponent("\(slug).md")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}

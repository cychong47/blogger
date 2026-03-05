import Foundation

struct ExportedPhoto: Identifiable, Codable {
    var id: String { filename }
    let filename: String        // e.g. "2026-03-05-photo.jpg"
    let markdownPath: String    // e.g. "/images/2026-03-05-photo.jpg"
    let localURL: URL           // file URL in App Group /pending/
    let exifDate: Date
}

struct PendingPostMetadata: Codable {
    let photos: [PhotoMetadata]

    struct PhotoMetadata: Codable {
        let filename: String
        let markdownPath: String
        let localPath: String   // relative path inside App Group container
        let exifDate: Date
    }
}

class PendingPost: ObservableObject {
    @Published var photos: [ExportedPhoto] = []
    @Published var title: String = ""
    @Published var slug: String = ""
    @Published var markdownBody: String = ""

    var isEmpty: Bool { photos.isEmpty && title.isEmpty }

    func clear() {
        photos = []
        title = ""
        slug = ""
        markdownBody = ""
    }
}

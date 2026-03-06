import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var pendingPost: PendingPost
    @EnvironmentObject var settings: AppSettings
    @State private var isDragTargeted = false

    var body: some View {
        ZStack {
            if pendingPost.isEmpty {
                WelcomeView(isDragTargeted: isDragTargeted)
            } else {
                PostEditorView()
            }

            // Transparent drop zone sits over everything, handles Photos.app file promises
            DropZone(isDragTargeted: $isDragTargeted, onDrop: handleDroppedPhotos)
        }
    }

    private func handleDroppedPhotos(_ photos: [ExportedPhoto]) {
        guard !photos.isEmpty else { return }
        let existingFilenames = Set(pendingPost.photos.map(\.filename))
        let newPhotos = photos.filter { !existingFilenames.contains($0.filename) }
        guard !newPhotos.isEmpty else { return }
        pendingPost.photos.append(contentsOf: newPhotos)

        let allPhotos = pendingPost.photos
        let date = allPhotos.first?.exifDate ?? Date()

        if pendingPost.title.isEmpty {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            pendingPost.title = f.string(from: date)
            pendingPost.slug = SlugGenerator.slugify(pendingPost.title)
        }

        pendingPost.markdownBody = MarkdownGenerator.initialMarkdown(
            title: pendingPost.title, date: date, photos: allPhotos)
    }
}

// MARK: - NSViewRepresentable wrapper

struct DropZone: NSViewRepresentable {
    @Binding var isDragTargeted: Bool
    let onDrop: ([ExportedPhoto]) -> Void

    func makeNSView(context: Context) -> DropTargetView {
        let view = DropTargetView()
        view.onFilesDropped = onDrop
        view.onDragEntered = { isDragTargeted = true }
        view.onDragExited  = { isDragTargeted = false }
        return view
    }

    func updateNSView(_ nsView: DropTargetView, context: Context) {
        nsView.onFilesDropped = onDrop
    }
}

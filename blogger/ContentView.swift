import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var pendingPost: PendingPost
    @EnvironmentObject var settings: AppSettings
    @State private var isDragTargeted = false
    @State private var isImporting = false

    var body: some View {
        ZStack {
            if pendingPost.isEmpty {
                WelcomeView(isDragTargeted: isDragTargeted)
            } else {
                PostEditorView()
            }

            DropZone(
                isDragTargeted: $isDragTargeted,
                onImportStarted: { isImporting = true },
                onDrop: handleDroppedPhotos
            )

            // Importing overlay
            if isImporting {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.4)
                    Text("Importing photos…")
                        .foregroundStyle(.white)
                        .font(.headline)
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func handleDroppedPhotos(_ photos: [ExportedPhoto]) {
        isImporting = false
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
    let onImportStarted: () -> Void
    let onDrop: ([ExportedPhoto]) -> Void

    func makeNSView(context: Context) -> DropTargetView {
        let view = DropTargetView()
        view.onFilesDropped = onDrop
        view.onImportStarted = onImportStarted
        view.onDragEntered = { isDragTargeted = true }
        view.onDragExited  = { isDragTargeted = false }
        return view
    }

    func updateNSView(_ nsView: DropTargetView, context: Context) {
        nsView.onFilesDropped = onDrop
        nsView.onImportStarted = onImportStarted
    }
}

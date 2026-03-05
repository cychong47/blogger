import SwiftUI
import AppKit

struct PostEditorView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var pendingPost: PendingPost

    @State private var showPublishSuccess = false
    @State private var publishedPath = ""
    @State private var publishError: String?
    @State private var showError = false

    var body: some View {
        VStack(spacing: 0) {
            // Header fields
            VStack(spacing: 8) {
                HStack {
                    Text("Title:")
                        .frame(width: 60, alignment: .trailing)
                        .foregroundStyle(.secondary)
                    TextField("Post title", text: $pendingPost.title)
                        .onChange(of: pendingPost.title) { newValue in
                            pendingPost.slug = SlugGenerator.slugify(newValue)
                        }
                }
                HStack {
                    Text("Filename:")
                        .frame(width: 60, alignment: .trailing)
                        .foregroundStyle(.secondary)
                    TextField("slug", text: $pendingPost.slug)
                        .font(.system(.body, design: .monospaced))
                    Text(".md")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider()

            HSplitView {
                // Left: markdown editor
                TextEditor(text: $pendingPost.markdownBody)
                    .font(.system(.body, design: .monospaced))
                    .frame(minWidth: 300)

                // Right: photo gallery
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(pendingPost.photos) { photo in
                            PhotoThumbnailView(photo: photo)
                        }
                    }
                    .padding()
                }
                .frame(minWidth: 200, maxWidth: 360)
                .background(Color(NSColor.controlBackgroundColor))
            }

            Divider()

            // Footer toolbar
            HStack {
                if let err = publishError {
                    Text(err)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer()
                Button("Publish") { publish() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [.command, .shift])
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .alert("Post Published", isPresented: $showPublishSuccess) {
            Button("OK") { clearState() }
        } message: {
            Text("Saved to:\n\(publishedPath)")
        }
        .onAppear { prepopulateMarkdown() }
    }

    private func prepopulateMarkdown() {
        guard !pendingPost.photos.isEmpty, pendingPost.markdownBody.isEmpty else { return }
        let date = pendingPost.photos.first?.exifDate ?? Date()
        pendingPost.markdownBody = MarkdownGenerator.initialMarkdown(
            title: pendingPost.title,
            date: date,
            photos: pendingPost.photos
        )
    }

    private func publish() {
        publishError = nil
        guard settings.isConfigured else {
            publishError = "Configure paths in Settings first."
            return
        }
        guard !pendingPost.slug.isEmpty else {
            publishError = "Filename (slug) cannot be empty."
            return
        }

        let date = pendingPost.photos.first?.exifDate ?? Date()
        do {
            // Copy photos to static dir
            try PhotoExporter.copyPendingToStatic(photos: pendingPost.photos, settings: settings)

            // Write markdown file
            let fileURL = try MarkdownGenerator.write(
                content: pendingPost.markdownBody,
                slug: pendingPost.slug,
                date: date,
                settings: settings
            )

            // Clear App Group pending data
            try SharedContainerService.clearPending()

            publishedPath = fileURL.path
            showPublishSuccess = true
        } catch {
            publishError = error.localizedDescription
        }
    }

    private func clearState() {
        pendingPost.clear()
    }
}

struct PhotoThumbnailView: View {
    let photo: ExportedPhoto

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(photo.filename)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            if let image = NSImage(contentsOf: photo.localURL) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 120)
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
            }
        }
    }
}

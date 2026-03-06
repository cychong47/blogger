import SwiftUI

@main
struct BloggerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = AppSettings()
    @StateObject private var pendingPost = PendingPost()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(pendingPost)
                .frame(minWidth: 800, minHeight: 500)
                .onAppear { appDelegate.pendingPost = pendingPost }
        }

        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var pendingPost: PendingPost?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == Constants.urlScheme {
            loadPendingPost()
        }
    }

    func loadPendingPost() {
        guard let post = pendingPost else { return }
        do {
            let photos = try SharedContainerService.loadExportedPhotos()
            guard !photos.isEmpty else { return }
            DispatchQueue.main.async {
                post.photos = photos
                let firstDate = photos.first?.exifDate ?? Date()
                if post.title.isEmpty {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    post.title = formatter.string(from: firstDate)
                    post.slug = SlugGenerator.slugify(post.title)
                }
                post.markdownBody = MarkdownGenerator.initialMarkdown(
                    title: post.title,
                    date: firstDate,
                    photos: photos
                )
            }
        } catch {
            print("[Blogger] Failed to load pending post: \(error)")
        }
    }
}

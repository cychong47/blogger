import SwiftUI

struct ContentView: View {
    @EnvironmentObject var pendingPost: PendingPost

    var body: some View {
        if pendingPost.isEmpty {
            WelcomeView()
        } else {
            PostEditorView()
        }
    }
}

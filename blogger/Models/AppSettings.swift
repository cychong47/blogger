import Foundation

class AppSettings: ObservableObject {
    private let defaults: UserDefaults

    @Published var contentPath: String {
        didSet { defaults.set(contentPath, forKey: Constants.UserDefaultsKeys.contentPath) }
    }

    @Published var staticImagesPath: String {
        didSet { defaults.set(staticImagesPath, forKey: Constants.UserDefaultsKeys.staticImagesPath) }
    }

    @Published var imageURLPrefix: String {
        didSet { defaults.set(imageURLPrefix, forKey: Constants.UserDefaultsKeys.imageURLPrefix) }
    }

    init() {
        guard let defaults = UserDefaults(suiteName: Constants.appGroupID) else {
            fatalError("Cannot access App Group UserDefaults: \(Constants.appGroupID)")
        }
        self.defaults = defaults
        self.contentPath = defaults.string(forKey: Constants.UserDefaultsKeys.contentPath) ?? ""
        self.staticImagesPath = defaults.string(forKey: Constants.UserDefaultsKeys.staticImagesPath) ?? ""
        self.imageURLPrefix = defaults.string(forKey: Constants.UserDefaultsKeys.imageURLPrefix) ?? "/images"
    }

    var isConfigured: Bool {
        !contentPath.isEmpty && !staticImagesPath.isEmpty
    }
}

import Foundation

enum AppInfo {
    static let name = "Mac Duo Effect"
    static let author = "jkvn"
    static let authorURL = URL(string: "https://github.com/jkvn")!
    static let repositoryName = "Mac-Duo-Effect"
    static let repositoryURL = URL(string: "https://github.com/jkvn/Mac-Duo-Effect")!

    static let summary = "Recreates the lid animation of the new iPhone Duo on the Mac: perspective, "
                       + "progressive blur and dimming as you move your MacBook lid."

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }
}

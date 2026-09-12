import SwiftUI

struct InfoPanel: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                identity
                Text(AppInfo.summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    link("Author", AppInfo.author, systemImage: "person.crop.circle", url: AppInfo.authorURL)
                    link("Source", AppInfo.repositoryName,
                         systemImage: "chevron.left.forwardslash.chevron.right",
                         url: AppInfo.repositoryURL)
                }
                Divider()
                Text("Only the built-in display is affected. Screen frames are processed in memory and are never saved or transmitted.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .frame(height: 300)
    }

    private var identity: some View {
        HStack(spacing: 12) {
            Image(systemName: "laptopcomputer")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(AppInfo.name).font(.headline)
                Text("Version \(AppInfo.version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func link(_ title: String, _ value: String, systemImage: String, url: URL) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(title).font(.callout)
            Spacer(minLength: 8)
            Link(value, destination: url)
                .font(.callout)
                .help(url.absoluteString)
        }
    }
}

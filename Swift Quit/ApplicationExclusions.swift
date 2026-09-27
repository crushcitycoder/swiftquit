import Foundation

enum ApplicationExclusions {
    static func shouldCloseApplication(
        at bundleURL: URL,
        excludeBehaviour: String?,
        configuredPaths: [String]
    ) -> Bool {
        let isConfigured = configuredPaths.contains {
            normalizedPath(for: $0) == bundleURL.standardizedFileURL.path
        }

        switch excludeBehaviour {
        case "excludeApps":
            return !isConfigured
        case "includeApps":
            return isConfigured
        default:
            return false
        }
    }

    static func normalizedPath(for configuredPath: String) -> String {
        if let url = URL(string: configuredPath), url.isFileURL {
            return url.standardizedFileURL.path
        }

        return URL(fileURLWithPath: configuredPath).standardizedFileURL.path
    }
}

enum ApplicationBundles {
    static func containsEmbeddedApplication(
        _ candidateBundleURL: URL,
        in applicationBundleURL: URL
    ) -> Bool {
        let applicationPath = applicationBundleURL.standardizedFileURL.path
        let candidatePath = candidateBundleURL.standardizedFileURL.path

        return candidatePath.hasPrefix(applicationPath + "/")
    }
}

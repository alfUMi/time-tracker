import Foundation

final class InMemorySessionStore: SessionStoring {
    private var snapshot = SessionStoreSnapshot.empty

    func loadSnapshot() -> SessionStoreSnapshot {
        snapshot
    }

    func saveSnapshot(_ snapshot: SessionStoreSnapshot) {
        self.snapshot = snapshot
    }
}

final class InMemorySettingsStore: SettingsStoring {
    private var settings = AppSettings()

    func loadSettings() -> AppSettings {
        settings
    }

    func saveSettings(_ settings: AppSettings) {
        self.settings = settings
    }
}

final class JSONSessionStore: SessionStoring {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL = PersistencePaths.sessionsFileURL) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func loadSnapshot() -> SessionStoreSnapshot {
        guard let data = try? Data(contentsOf: fileURL) else {
            return .empty
        }

        return (try? decoder.decode(SessionStoreSnapshot.self, from: data)) ?? .empty
    }

    func saveSnapshot(_ snapshot: SessionStoreSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }

        do {
            try PersistencePaths.ensureBaseDirectoryExists()
            try data.write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Failed to save session snapshot: \(error)")
        }
    }
}

final class JSONSettingsStore: SettingsStoring {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL = PersistencePaths.settingsFileURL) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func loadSettings() -> AppSettings {
        guard let data = try? Data(contentsOf: fileURL) else {
            return AppSettings()
        }

        return (try? decoder.decode(AppSettings.self, from: data)) ?? AppSettings()
    }

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else { return }

        do {
            try PersistencePaths.ensureBaseDirectoryExists()
            try data.write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Failed to save settings: \(error)")
        }
    }
}

struct NotificationServiceStub: NotificationServicing {
    func requestAuthorizationIfNeeded() {}

    func scheduleBreakReminder(after minutes: Int) {}

    func clearBreakReminder() {}
}

struct LaunchAtLoginControllerStub: LaunchAtLoginControlling {
    func setEnabled(_ enabled: Bool) {}
}

enum PersistencePaths {
    static let baseDirectoryURL: URL = {
        let fileManager = FileManager.default
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")

        return applicationSupport
            .appendingPathComponent("MacBookNotchTracker", isDirectory: true)
    }()

    static let sessionsFileURL = baseDirectoryURL.appendingPathComponent("sessions.json")
    static let settingsFileURL = baseDirectoryURL.appendingPathComponent("settings.json")

    static func ensureBaseDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: baseDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}

import Foundation

struct JSONFileStorage {
    let directory: URL

    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            self.directory = appSupport.appendingPathComponent(
                Bundle.main.bundleIdentifier ?? "Notes",
                isDirectory: true
            )
        }
    }

    func load<Value: Decodable>(_ type: Value.Type, from filename: String) throws -> Value {
        let data = try Data(contentsOf: directory.appendingPathComponent(filename))
        return try JSONDecoder().decode(type, from: data)
    }

    func save<Value: Encodable>(_ value: Value, to filename: String) throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(value)
        try data.write(to: directory.appendingPathComponent(filename), options: .atomic)
    }
}

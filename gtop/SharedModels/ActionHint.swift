import Foundation

public enum ActionHintKind: String, Codable, Equatable, Sendable {
    case cpu
    case memory
    case network
    case power
    case thermal
}

public enum ActionHintSeverity: String, Codable, Equatable, Sendable {
    case info
    case warning
}

public struct ActionHint: Codable, Equatable, Sendable {
    public var kind: ActionHintKind
    public var severity: ActionHintSeverity
    public var title: String
    public var message: String

    public init(kind: ActionHintKind, severity: ActionHintSeverity, title: String, message: String) {
        self.kind = kind
        self.severity = severity
        self.title = title
        self.message = message
    }
}

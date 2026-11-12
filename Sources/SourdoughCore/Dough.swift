import Foundation

/// What kind of jar it is. Shown by the lid color.
public enum DoughType: String, Codable, Sendable {
    case starter, bread, pizza
}
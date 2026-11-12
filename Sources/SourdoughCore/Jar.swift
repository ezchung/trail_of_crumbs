import Foundation

/// What kind of jar it is. Shown by the lid color.
public enum JarType: String, Codable, Sendable {
    case starter, bread, pizza
}
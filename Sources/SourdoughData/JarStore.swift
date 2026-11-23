/*
Talks to Supabase: sign up / log in, load the shelf, save jars and events.

Saving works like the Core model: every action is one new row in jar_events.
Nothing is ever "updated" except a jar's name / schedule.
*/

import Foundation
import Supabase
import SourdoughCore

public final class JarStore: Sendable {
    let client: SupabaseClient

    /// `url` and `anonKey` come from Supabase → Project Settings → API.
    /// The anon key is safe to ship in an app; row-level security protects the data.
    public init(url: URL, anonKey: String, sessionStorage: any AuthLocalStorage = MemorySessionStorage()) {
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(auth: .init(storage: sessionStorage))
        )
    }

    // MARK: - Accounts (email + password, DESIGN.md → Welcome screen)

    public func signUp(email: String, password: String) async throws {
        _ = try await client.auth.signUp(email: email, password: password)
    }

    public func logIn(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
    }

    public func logOut() async throws {
        try await client.auth.signOut()
    }

    public var isLoggedIn: Bool { client.auth.currentUser != nil }

    // MARK: - Shelf

    /// Every jar for the logged-in user, with its full history.
    public func loadShelf() async throws -> [Dough] {
        let rows: [JarRow] = try await client
            .from("jars")
            .select("*, jar_events(*)")
            .order("created_at")
            .execute()
            .value
        return try rows.map { try $0.toDough() }
    }

    /// Save a brand-new jar and its starting event.
    public func add(_ dough: Dough) async throws {
        try await client.from("jars").insert(JarRow(dough)).execute()
        try await client.from("jar_events")
            .insert(dough.events.map { EventRow($0, jarId: dough.id) })
            .execute()
    }

    /// Save one action (feed, take out, report…). Call after the Dough method that made it.
    public func save(_ event: JarEvent, in jarId: UUID) async throws {
        try await client.from("jar_events").insert(EventRow(event, jarId: jarId)).execute()
    }

    /// Undo: delete one event row.
    public func delete(eventId: UUID) async throws {
        try await client.from("jar_events").delete().eq("id", value: eventId).execute()
    }

    /// Rename or change schedule.
    public func update(_ dough: Dough) async throws {
        try await client.from("jars").update(JarRow(dough)).eq("id", value: dough.id).execute()
    }

    /// Delete a jar. Its events go with it (on delete cascade).
    public func delete(jarId: UUID) async throws {
        try await client.from("jars").delete().eq("id", value: jarId).execute()
    }
}

/// Keeps the login session in memory only (lost when the program quits).
/// Linux has no Keychain, so this is for the PC. On the iPhone, pass
/// `KeychainLocalStorage()` instead so people stay logged in.
public final class MemorySessionStorage: AuthLocalStorage, @unchecked Sendable {
    private var values: [String: Data] = [:]
    private let lock = NSLock()

    public init() {}

    public func store(key: String, value: Data) throws { lock.withLock { values[key] = value } }
    public func retrieve(key: String) throws -> Data? { lock.withLock { values[key] } }
    public func remove(key: String) throws { lock.withLock { _ = values.removeValue(forKey: key) } }
}

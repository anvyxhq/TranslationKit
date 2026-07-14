//
//  Translator.swift
//  TranslationKit
//
//  Created by AnhPT on 03/07/2026.
//

import SwiftUI
import Translation

public enum TranslationError: Error {
    /// A translation is already in progress on this translator.
    case busy
}

/// A headless-feeling façade over the Translation framework.
///
/// The framework only vends a `TranslationSession` through SwiftUI's
/// `translationTask` modifier, so a host view must be attached once (typically
/// near the app root) via `View.translationHost(_:)`. After that,
/// call ``translate(_:from:to:)`` from anywhere with plain `async/await`:
///
/// ```swift
/// @State private var translator = Translator()
///
/// var body: some View {
///     ContentView()
///         .translationHost(translator)   // attach once
/// }
///
/// // elsewhere:
/// let vi = try await translator.translate(["Hello", "World"],
///                                         to: .init(identifier: "vi"))
/// ```
@Observable
@MainActor
public final class Translator {

    // Read by the host modifier's body, so it must stay observation-tracked.
    fileprivate var configuration: TranslationSession.Configuration?
    // Internal in-flight state — never read from a view, so exclude from tracking.
    @ObservationIgnored private var pending: CheckedContinuation<[String], Error>?
    @ObservationIgnored private var operation: Operation?

    private enum Operation {
        case translate([String])
        case prepare              // download the offline model for the pair
    }

    public init() {}

    /// Translate `texts` into `target` (optionally forcing `source`; `nil`
    /// lets the framework auto-detect). Results are returned in input order.
    ///
    /// - Throws: ``TranslationError/busy`` if another translation is in flight.
    @discardableResult
    public func translate(
        _ texts: [String],
        from source: Locale.Language? = nil,
        to target: Locale.Language
    ) async throws -> [String] {
        try await run(.translate(texts), from: source, to: target)
    }

    /// Convenience for a single string.
    @discardableResult
    public func translate(
        _ text: String,
        from source: Locale.Language? = nil,
        to target: Locale.Language
    ) async throws -> String {
        try await translate([text], from: source, to: target).first ?? text
    }

    /// Download the on-device model for a language pair (presenting the system's
    /// download prompt if needed), so later translations run fully offline.
    /// Check ``TranslationAvailability`` first to skip when already installed.
    ///
    /// - Throws: ``TranslationError/busy`` if a translation/prepare is in flight.
    public func prepare(from source: Locale.Language? = nil, to target: Locale.Language) async throws {
        _ = try await run(.prepare, from: source, to: target)
    }

    @discardableResult
    private func run(_ operation: Operation,
                     from source: Locale.Language?,
                     to target: Locale.Language) async throws -> [String] {
        guard pending == nil else { throw TranslationError.busy }
        self.operation = operation
        return try await withCheckedThrowingContinuation { continuation in
            pending = continuation
            if let current = configuration, current.target == target, current.source == source {
                // Same pair as last time — re-run the task with the same config.
                configuration?.invalidate()
            } else {
                configuration = .init(source: source, target: target)
            }
        }
    }

    // Called by the host modifier when a session becomes available.
    //
    // `session` is `sending` so the non-`Sendable` value arrives in its own
    // region and can cross into the framework's `@concurrent` batch call.
    fileprivate func perform(with session: sending TranslationSession) async {
        guard let continuation = pending, let operation else { return }
        pending = nil
        self.operation = nil
        do {
            switch operation {
            case .translate(let texts):
                continuation.resume(returning: try await session.translate(texts))
            case .prepare:
                try await session.prepareTranslation()
                continuation.resume(returning: [])
            }
        } catch {
            continuation.resume(throwing: error)
        }
    }
}

private struct TranslationHostModifier: ViewModifier {
    let translator: Translator

    func body(content: Content) -> some View {
        content.translationTask(translator.configuration) { session in
            await translator.perform(with: session)
        }
    }
}

public extension View {
    /// Attach a ``Translator``'s hidden translation task to this view. Attach
    /// once high in the hierarchy so `translator.translate(...)` works app-wide.
    func translationHost(_ translator: Translator) -> some View {
        modifier(TranslationHostModifier(translator: translator))
    }
}

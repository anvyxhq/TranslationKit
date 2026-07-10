//
//  TranslationAvailability.swift
//  TranslationKit
//
//  Created by AnhPT on 03/07/2026.
//

import Foundation
import Translation

/// Thin wrapper over `LanguageAvailability` — checks whether a language pair is
/// supported / downloaded before attempting a translation.
///
/// This part of the API is fully headless (no SwiftUI view required) and is
/// safe to call from anywhere.
public struct TranslationAvailability {

    public init() {}

    /// Support/installation status for translating `source` → `target`.
    ///
    /// `.installed` means the on-device model is downloaded and ready;
    /// `.supported` means it can be downloaded on first use; `.unsupported`
    /// means the pair isn't available.
    public func status(
        from source: Locale.Language,
        to target: Locale.Language
    ) async -> LanguageAvailability.Status {
        // `LanguageAvailability` is a non-`Sendable` stateless query object;
        // create it locally so it stays in its own region and can cross into
        // the framework's `nonisolated` async call.
        await LanguageAvailability().status(from: source, to: target)
    }

    /// All languages the Translation framework can translate to/from.
    ///
    /// `@concurrent` so this runs on the generic executor — matching the
    /// framework's `nonisolated` async getter, which won't accept a
    /// non-`Sendable` receiver transferred from a caller-isolated context.
    @concurrent
    public func supportedLanguages() async -> [Locale.Language] {
        await LanguageAvailability().supportedLanguages
    }

    /// Convenience: is this pair usable at all (installed or downloadable)?
    public func isSupported(
        from source: Locale.Language,
        to target: Locale.Language
    ) async -> Bool {
        switch await status(from: source, to: target) {
        case .installed, .supported: return true
        case .unsupported: return false
        @unknown default: return false
        }
    }
}

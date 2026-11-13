//
//  TranslationSession+Batch.swift
//  TranslationKit
//
//  Created by AnhPT on 03/07/2026.
//

import Translation

public extension TranslationSession {

    /// Translate an ordered array of strings in one batch, returning the
    /// results in the **same order** as the input.
    ///
    /// Wraps the framework's `translations(from:)` batch call, tagging each
    /// request with its index (`clientIdentifier`) so responses — which may
    /// arrive in any order — are re-sorted back to the caller's order.
    ///
    /// - Note: All strings are assumed to be in the session's source language;
    ///   the Translation framework does not allow mixed source languages in one
    ///   batch. Runs on-device and requires a physical device (not Simulator).
    ///
    /// - Parameter protectingPlaceholders: when `true` (default), printf
    ///   placeholders (`%@`, `%1$d`, …) are masked before translating and put
    ///   back afterwards (see ``PlaceholderMasking``). A string whose
    ///   placeholders do not survive the round trip is returned untranslated.
    ///
    /// `@concurrent` so this runs on the generic executor — matching the
    /// framework's `nonisolated` `translations(from:)`, which won't accept the
    /// non-`Sendable` session transferred from a caller-isolated context.
    @concurrent
    func translate(_ texts: [String], protectingPlaceholders: Bool = true) async throws -> [String] {
        guard !texts.isEmpty else { return [] }

        let masked = texts.map {
            protectingPlaceholders ? PlaceholderMasking.mask($0) : .init(text: $0, placeholders: [])
        }
        let requests = masked.enumerated().map { index, item in
            Request(sourceText: item.text, clientIdentifier: String(index))
        }
        let responses = try await translations(from: requests)

        var ordered = [String?](repeating: nil, count: texts.count)
        for response in responses {
            if let id = response.clientIdentifier, let i = Int(id), ordered.indices.contains(i) {
                ordered[i] = response.targetText
            }
        }
        // Fall back to positional order for any response that lacked an identifier.
        return ordered.enumerated().map { offset, translated in
            guard let translated else { return texts[offset] }
            let placeholders = masked[offset].placeholders
            guard !placeholders.isEmpty else { return translated }
            return PlaceholderMasking.restore(translated, placeholders: placeholders) ?? texts[offset]
        }
    }

    /// Convenience for translating a single string.
    @concurrent
    func translate(_ text: String, protectingPlaceholders: Bool = true) async throws -> String {
        try await translate([text], protectingPlaceholders: protectingPlaceholders).first ?? text
    }
}

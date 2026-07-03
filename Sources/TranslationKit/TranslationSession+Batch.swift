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
    func translate(_ texts: [String]) async throws -> [String] {
        guard !texts.isEmpty else { return [] }

        let requests = texts.enumerated().map { index, text in
            Request(sourceText: text, clientIdentifier: String(index))
        }
        let responses = try await translations(from: requests)

        var ordered = [String?](repeating: nil, count: texts.count)
        for response in responses {
            if let id = response.clientIdentifier, let i = Int(id), ordered.indices.contains(i) {
                ordered[i] = response.targetText
            }
        }
        // Fall back to positional order for any response that lacked an identifier.
        return ordered.enumerated().map { $0.element ?? texts[$0.offset] }
    }

    /// Convenience for translating a single string.
    func translate(_ text: String) async throws -> String {
        try await translate([text]).first ?? text
    }
}

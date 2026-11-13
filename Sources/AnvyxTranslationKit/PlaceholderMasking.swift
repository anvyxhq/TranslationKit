//
//  PlaceholderMasking.swift
//  TranslationKit
//

import Foundation

/// Shields printf-style placeholders (`%@`, `%d`, `%1$@`, `%.2f`, `%%` …) from
/// a translation engine, which would otherwise be free to drop, reorder into
/// nonsense, or rewrite them.
///
/// ``mask(_:)`` swaps each placeholder for a neutral token (`⟦0⟧`, `⟦1⟧`, …)
/// that engines leave alone; ``restore(_:placeholders:)`` puts the original
/// placeholders back into the translated text.
///
/// ```swift
/// let masked = PlaceholderMasking.mask("%d of %@")        // "⟦0⟧ of ⟦1⟧"
/// let restored = PlaceholderMasking.restore("⟦1⟧ : ⟦0⟧", placeholders: masked.placeholders)
/// // "%@ : %d" — same placeholders, same arguments
/// ```
///
/// - Note: Restoring puts each placeholder back verbatim, so when a translation
///   changes the word order of *non-positional* placeholders (`%d … %@` →
///   `%@ … %d`) the result no longer matches the original argument order. Use
///   positional placeholders (`%1$d`, `%2$@`) in strings whose order may change.
public enum PlaceholderMasking {

    /// A text with its placeholders replaced by tokens.
    public struct Masked: Equatable, Sendable {
        /// The text to hand to the translation engine.
        public let text: String
        /// The placeholders that were removed; token `⟦n⟧` stands for `placeholders[n]`.
        public let placeholders: [String]
    }

    /// Replaces every placeholder in `text` with a token.
    ///
    /// Only unambiguous specifiers are masked — a percent sign used as plain
    /// text (`"50% off"`, `"100%"`) is left for the engine to translate. Text
    /// that already contains the token brackets is returned unmasked.
    public static func mask(_ text: String) -> Masked {
        let scalars = Array(text.unicodeScalars)
        guard !scalars.contains(where: { $0 == open || $0 == close }) else {
            return Masked(text: text, placeholders: [])
        }
        var output = String.UnicodeScalarView()
        var placeholders: [String] = []
        var index = 0
        while index < scalars.count {
            if scalars[index] == "%", let end = specifierEnd(in: scalars, from: index) {
                var specifier = String.UnicodeScalarView()
                specifier.append(contentsOf: scalars[index..<end])
                output.append(contentsOf: token(placeholders.count).unicodeScalars)
                placeholders.append(String(specifier))
                index = end
            } else {
                output.append(scalars[index])
                index += 1
            }
        }
        return Masked(text: String(output), placeholders: placeholders)
    }

    /// Puts `placeholders` back into a translated text.
    ///
    /// - Returns: the restored text, or `nil` when the translation did not keep
    ///   the tokens intact — a token is missing, appears more than once, or an
    ///   unknown token turned up. Callers should then fall back to the source text.
    public static func restore(_ translated: String, placeholders: [String]) -> String? {
        let scalars = Array(translated.unicodeScalars)
        var output = String.UnicodeScalarView()
        var seen = Set<Int>()
        var index = 0
        while index < scalars.count {
            let scalar = scalars[index]
            if scalar == close { return nil }
            guard scalar == open else {
                output.append(scalar)
                index += 1
                continue
            }
            var cursor = index + 1
            var number = 0
            var digits = 0
            while cursor < scalars.count, let digit = asciiDigit(scalars[cursor]), digits < 6 {
                number = number * 10 + digit
                digits += 1
                cursor += 1
            }
            guard digits > 0, cursor < scalars.count, scalars[cursor] == close,
                  placeholders.indices.contains(number), seen.insert(number).inserted
            else { return nil }
            output.append(contentsOf: placeholders[number].unicodeScalars)
            index = cursor + 1
        }
        return seen.count == placeholders.count ? String(output) : nil
    }

    // MARK: - Internals

    private static let open: Unicode.Scalar = "⟦"
    private static let close: Unicode.Scalar = "⟧"

    private static func token(_ index: Int) -> String { "⟦\(index)⟧" }

    private static func asciiDigit(_ scalar: Unicode.Scalar) -> Int? {
        scalar.value >= 0x30 && scalar.value <= 0x39 ? Int(scalar.value - 0x30) : nil
    }

    /// End index (exclusive) of the specifier starting at `start` (a `%`), or
    /// `nil` when what follows is not one. The space flag is deliberately not
    /// accepted: `"50% off"` is far more likely prose than an octal specifier.
    private static func specifierEnd(in scalars: [Unicode.Scalar], from start: Int) -> Int? {
        var index = start + 1
        guard index < scalars.count else { return nil }
        if scalars[index] == "%" { return index + 1 }

        func skipDigits() -> Bool {
            let begin = index
            while index < scalars.count, asciiDigit(scalars[index]) != nil { index += 1 }
            return index > begin
        }

        let afterPercent = index
        if !(skipDigits() && index < scalars.count && scalars[index] == "$") {
            index = afterPercent
        } else {
            index += 1
        }
        while index < scalars.count, "-+#0'".unicodeScalars.contains(scalars[index]) { index += 1 }
        _ = skipDigits()
        if index < scalars.count, scalars[index] == "." {
            index += 1
            _ = skipDigits()
        }
        while index < scalars.count, "hlqztjL".unicodeScalars.contains(scalars[index]) { index += 1 }
        guard index < scalars.count, "@diuxXoDUOcCfFeEgGaAsSp".unicodeScalars.contains(scalars[index]) else { return nil }
        return index + 1
    }
}

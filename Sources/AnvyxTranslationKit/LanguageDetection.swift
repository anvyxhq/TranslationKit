//
//  LanguageDetection.swift
//  TranslationKit
//
//  Created by AnhPT on 14/07/2026.
//

import Foundation
import NaturalLanguage

/// On-device language identification via `NLLanguageRecognizer`. The Translation
/// framework auto-detects the source when you pass `from: nil`, but this lets you
/// know *which* language a string is (e.g. to pick a target or show a hint)
/// without a translation session — and it runs on the Simulator too.
public enum LanguageDetection {

    /// The most likely language of `text`, or `nil` if none can be determined.
    public static func detect(_ text: String) -> Locale.Language? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let language = recognizer.dominantLanguage else { return nil }
        return Locale.Language(identifier: language.rawValue)
    }

    /// Ranked language guesses with their probabilities (`0…1`).
    public static func hypotheses(_ text: String, maximum: Int = 3) -> [Locale.Language: Double] {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return Dictionary(uniqueKeysWithValues: recognizer.languageHypotheses(withMaximum: maximum)
            .map { (Locale.Language(identifier: $0.key.rawValue), $0.value) })
    }
}

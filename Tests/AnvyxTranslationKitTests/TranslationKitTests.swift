//
//  TranslationKitTests.swift
//  TranslationKit
//
//  Created by AnhPT on 03/07/2026.
//

import XCTest
import Observation
import Translation
@testable import AnvyxTranslationKit

/// Compile-time requirement: fails to build if `T` is not `@Observable`.
private func requireObservable<T: Observable>(_ value: T) -> T { value }

// Compile-level smoke tests. Actual translation runs only on a physical device
// (the Translation framework is unavailable in the Simulator), so these verify
// the API surface builds and wires up, not runtime translation output.
final class TranslationKitTests: XCTestCase {

    @MainActor
    func testTypesConstruct() {
        _ = Translator()
        _ = TranslationAvailability()
        _ = TranslationSession.Configuration(source: nil, target: Locale.Language(identifier: "vi"))
    }

    @MainActor
    func testTranslatorIsObservable() {
        _ = requireObservable(Translator())
    }

    // Language detection uses NaturalLanguage, so it runs in the Simulator.

    func testDetectsEnglish() {
        let language = LanguageDetection.detect("Hello, how are you doing today?")
        XCTAssertEqual(language?.languageCode?.identifier, "en")
    }

    func testDetectsVietnamese() {
        let language = LanguageDetection.detect("Xin chào, hôm nay bạn khỏe không?")
        XCTAssertEqual(language?.languageCode?.identifier, "vi")
    }

    func testDetectReturnsNilForEmpty() {
        XCTAssertNil(LanguageDetection.detect(""))
    }

    func testHypothesesAreRanked() {
        let hypotheses = LanguageDetection.hypotheses("Bonjour tout le monde", maximum: 3)
        XCTAssertFalse(hypotheses.isEmpty)
        XCTAssertLessThanOrEqual(hypotheses.count, 3)
    }
}

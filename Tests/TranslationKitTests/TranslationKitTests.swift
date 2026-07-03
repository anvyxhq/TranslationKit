//
//  TranslationKitTests.swift
//  TranslationKit
//
//  Created by AnhPT on 03/07/2026.
//

import XCTest
import Translation
@testable import TranslationKit

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
}

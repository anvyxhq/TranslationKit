//
//  PlaceholderMaskingTests.swift
//  TranslationKit
//

import XCTest
@testable import AnvyxTranslationKit

final class PlaceholderMaskingTests: XCTestCase {

    func testMasksEverySpecifier() {
        let masked = PlaceholderMasking.mask("%@ has %1$d items, %.2f%% of %-5ld (%lld)")
        XCTAssertEqual(masked.text, "⟦0⟧ has ⟦1⟧ items, ⟦2⟧⟦3⟧ of ⟦4⟧ (⟦5⟧)")
        XCTAssertEqual(masked.placeholders, ["%@", "%1$d", "%.2f", "%%", "%-5ld", "%lld"])
    }

    func testLeavesPlainTextAlone() {
        for text in ["Hello world", "50% off today", "100%", "5 %, dann", "Xin chào 🇻🇳", ""] {
            XCTAssertEqual(PlaceholderMasking.mask(text), .init(text: text, placeholders: []), text)
        }
    }

    func testTextAlreadyContainingTokensIsNotMasked() {
        let text = "⟦0⟧ and %@"
        XCTAssertEqual(PlaceholderMasking.mask(text), .init(text: text, placeholders: []))
    }

    func testRoundTrip() {
        let source = "Xin chào %@, bạn có %d tin nhắn 🎉 (%.1f%%)"
        let masked = PlaceholderMasking.mask(source)
        XCTAssertEqual(PlaceholderMasking.restore(masked.text, placeholders: masked.placeholders), source)
    }

    func testRestoreAfterReordering() {
        let masked = PlaceholderMasking.mask("%1$d of %2$@")
        XCTAssertEqual(PlaceholderMasking.restore("⟦1⟧ : ⟦0⟧", placeholders: masked.placeholders), "%2$@ : %1$d")
    }

    func testRestoreFailsWhenTokensAreNotIntact() {
        let placeholders = ["%d", "%@"]
        XCTAssertNil(PlaceholderMasking.restore("only ⟦0⟧", placeholders: placeholders))           // missing
        XCTAssertNil(PlaceholderMasking.restore("⟦0⟧ ⟦0⟧ ⟦1⟧", placeholders: placeholders))        // duplicated
        XCTAssertNil(PlaceholderMasking.restore("⟦0⟧ ⟦1⟧ ⟦2⟧", placeholders: placeholders))        // unknown
        XCTAssertNil(PlaceholderMasking.restore("[0] ⟦1⟧", placeholders: placeholders))            // rewritten
        XCTAssertNil(PlaceholderMasking.restore("⟦0 ⟧ ⟦1⟧", placeholders: placeholders))           // broken
        XCTAssertNil(PlaceholderMasking.restore("⟦0⟧ ⟦1⟧ ⟧", placeholders: placeholders))          // stray bracket
        XCTAssertNil(PlaceholderMasking.restore("⟦٠⟧ ⟦1⟧", placeholders: placeholders))            // localized digit
    }

    func testRestoreWithoutPlaceholders() {
        XCTAssertEqual(PlaceholderMasking.restore("Bonjour", placeholders: []), "Bonjour")
        XCTAssertNil(PlaceholderMasking.restore("Bonjour ⟦0⟧", placeholders: []))
    }
}

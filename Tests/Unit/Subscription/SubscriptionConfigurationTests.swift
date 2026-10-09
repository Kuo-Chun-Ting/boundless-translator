import Foundation
import Testing
@testable import BoundlessTranslator

@Test
func test_configuration_when_product_or_public_policy_is_invalid_then_does_not_offer_purchase() {
    // Arrange
    let invalidValues: [(String?, String?)] = [
        (nil, "https://example.com/privacy"),
        ("", "https://example.com/privacy"),
        ("annual subscription", "https://example.com/privacy"),
        ("annual", nil), ("annual", "file:///private/policy"),
        ("annual", "https://"), ("annual", "http://example.com/privacy"),
        ("annual", "https://user:secret@example.com/privacy")
    ]

    // Act & Assert
    for (productID, policyURL) in invalidValues {
        #expect(SubscriptionConfiguration(productID: productID, privacyPolicyURL: policyURL) == nil)
    }
}

@Test
func test_configuration_when_valid_then_supplies_product_and_policy_to_store_view() throws {
    // Arrange & Act
    let configuration = try #require(SubscriptionConfiguration(
        productID: "com.lillard.BoundlessTranslator.annual",
        privacyPolicyURL: "https://example.com/privacy"
    ))

    // Assert
    #expect(configuration.productID == "com.lillard.BoundlessTranslator.annual")
    #expect(configuration.privacyPolicyURL.absoluteString == "https://example.com/privacy")
}

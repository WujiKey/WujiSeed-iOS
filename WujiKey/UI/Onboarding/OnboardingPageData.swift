//
//  OnboardingPageData.swift
//  WujiKey
//
//  Data model for onboarding pages
//

import Foundation

/// Represents the type of content layout for an onboarding page
enum OnboardingPageType {
    /// Page 1: Hero title with philosophy message
    case philosophy
    /// Before/After comparison cards (unused)
    case comparison
    /// Bullet points with security features (unused)
    case bulletPoints
    /// Page 3: Flow diagram showing how it works
    case flowDiagram
    /// Page 4: Call to action with start button
    case callToAction
}

/// Data model for a single onboarding page
struct OnboardingPageData {
    let pageType: OnboardingPageType
    let titleKey: String
    let messageKey: String?
    let iconName: String?
    let iconEmoji: String?
    let customImageName: String?

    // For comparison page (Page 2)
    let beforeTitleKey: String?
    let beforeContentKey: String?
    let afterTitleKey: String?
    let afterContentKey: String?

    // For bullet points page (Page 3)
    let bulletPointKeys: [String]?
    let bulletPointIcons: [String]?
    let bulletPointEmojis: [String]?

    // For flow diagram page (Page 4)
    let flowStepKeys: [String]?

    // For CTA page (Page 5)
    let buttonKey: String?

    /// Creates all 5 onboarding pages
    static func createAllPages() -> [OnboardingPageData] {
        return [
            // Page 1: Philosophy
            OnboardingPageData(
                pageType: .philosophy,
                titleKey: "onboarding.page1.title",
                messageKey: "onboarding.page1.message",
                iconName: "brain.head.profile",
                iconEmoji: "🧠",
                customImageName: nil,
                beforeTitleKey: nil,
                beforeContentKey: nil,
                afterTitleKey: nil,
                afterContentKey: nil,
                bulletPointKeys: nil,
                bulletPointIcons: nil,
                bulletPointEmojis: nil,
                flowStepKeys: nil,
                buttonKey: nil
            ),

            // Page 2: F9Grid
            OnboardingPageData(
                pageType: .philosophy,
                titleKey: "onboarding.page2.title",
                messageKey: "onboarding.page2.message",
                iconName: nil,
                iconEmoji: "🌐",
                customImageName: "f9grid_illustration",
                beforeTitleKey: nil,
                beforeContentKey: nil,
                afterTitleKey: nil,
                afterContentKey: nil,
                bulletPointKeys: nil,
                bulletPointIcons: nil,
                bulletPointEmojis: nil,
                flowStepKeys: nil,
                buttonKey: nil
            ),

            // Page 3: How It Works
            OnboardingPageData(
                pageType: .flowDiagram,
                titleKey: "onboarding.page4.title",
                messageKey: nil,
                iconName: nil,
                iconEmoji: nil,
                customImageName: nil,
                beforeTitleKey: nil,
                beforeContentKey: nil,
                afterTitleKey: nil,
                afterContentKey: nil,
                bulletPointKeys: nil,
                bulletPointIcons: nil,
                bulletPointEmojis: nil,
                flowStepKeys: [
                    "onboarding.page4.step1",
                    "onboarding.page4.step2",
                    "onboarding.page4.step3",
                    "onboarding.page4.step4"
                ],
                buttonKey: nil
            ),

            // Page 4: Call to Action
            OnboardingPageData(
                pageType: .callToAction,
                titleKey: "onboarding.page5.title",
                messageKey: "onboarding.page5.message",
                iconName: "sparkles",
                iconEmoji: "✨",
                customImageName: nil,
                beforeTitleKey: nil,
                beforeContentKey: nil,
                afterTitleKey: nil,
                afterContentKey: nil,
                bulletPointKeys: nil,
                bulletPointIcons: nil,
                bulletPointEmojis: nil,
                flowStepKeys: nil,
                buttonKey: "onboarding.page5.button"
            )
        ]
    }
}

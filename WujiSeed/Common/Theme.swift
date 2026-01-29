//
//  Theme.swift
//  WujiSeed
//
//  Centralized management of app colors, fonts, layout and other theme constants
//

import UIKit

/// App theme configuration
enum Theme {

    // MARK: - Colors

    /// Color constants
    enum Colors {
        /// Elegant deep blue #002B5B - for primary interactive elements
        static let elegantBlue = UIColor(red: 0.0, green: 0.169, blue: 0.357, alpha: 1.0)

        /// Soft amber orange #C78540 - for warning alerts
        static let softAmber = UIColor(red: 0.78, green: 0.52, blue: 0.25, alpha: 1.0)

        // MARK: - Text Colors

        /// Dark gray text - primary content
        static let textDark = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)

        /// Medium gray text - secondary content
        static let textMedium = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)

        /// Light gray text - hint information
        static let textLight = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)

        /// Brown gray text - warning card text
        static let textBrown = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)

        // MARK: - Tag Colors

        /// Secret tag text color - orange red
        static let tagSecretText = UIColor(red: 0.85, green: 0.35, blue: 0.13, alpha: 1.0)

        /// Secret tag background color - light orange red
        static let tagSecretBackground = UIColor(red: 0.85, green: 0.35, blue: 0.13, alpha: 0.15)

        /// Public tag text color - green
        static let tagPublicText = UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0)

        /// Public tag background color - light green
        static let tagPublicBackground = UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 0.15)

        // MARK: - Card Background Colors

        /// Context card background color (light blue)
        static let contextCardBackground = UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0)

        /// General blue background
        static let blueBackground = UIColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 1.0)

        /// Light gray background
        static let grayBackground = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)

        /// Orange warning background
        static let orangeBackground = UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)

        /// Light yellow background
        static let yellowBackground = UIColor(red: 1.0, green: 0.99, blue: 0.95, alpha: 1.0)

        /// Success card background color - light green
        static let successBackground = UIColor(red: 0.94, green: 0.98, blue: 0.94, alpha: 1.0)

        /// Disabled input background color - light gray
        static let disabledInputBackground = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)

        // MARK: - Border Colors

        /// Blue card border
        static let borderBlue = UIColor(red: 0.85, green: 0.90, blue: 0.98, alpha: 1.0)

        /// Orange warning border
        static let borderOrange = UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)

        /// Green success border
        static let borderGreen = UIColor(red: 0.5, green: 0.8, blue: 0.5, alpha: 1.0)

        /// Light gray border
        static let borderGray = UIColor(red: 0.9, green: 0.9, blue: 0.92, alpha: 1.0)

        // MARK: - Others

        /// Title text color (deep blue gray)
        static let titleText = UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0)

        /// Subtitle text color
        static let subtitleText = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)

        /// Input field background color
        static let inputBackground = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)

        /// Disabled button background color (deep blue gray #7B8794)
        static let disabledButtonBackground = UIColor(red: 0.482, green: 0.529, blue: 0.580, alpha: 1.0)

        /// Result card background color
        static let resultBackground = UIColor(red: 0.97, green: 0.99, blue: 1.0, alpha: 1.0)

        // MARK: - System Colors (semantic wrappers)

        /// Error/Destructive color
        static let error = UIColor.systemRed

        /// Warning color (system orange)
        static let systemWarning = UIColor.systemOrange

        /// System blue (links, highlights)
        static let systemBlue = UIColor.systemBlue

        /// Purple highlight
        static let highlight = UIColor.systemPurple

        // MARK: - Overlay Colors

        /// Dark overlay (50% black)
        static let overlayDark = UIColor.black.withAlphaComponent(0.5)

        /// Toast background (80% black)
        static let toastBackground = UIColor.black.withAlphaComponent(0.8)

        /// Light track color (30% light gray)
        static let trackLight = UIColor.lightGray.withAlphaComponent(0.3)

        /// Separator light (30% light gray)
        static let separatorLight = UIColor.lightGray.withAlphaComponent(0.3)

        // MARK: - Warning Card Colors

        /// Warning card background (red tint)
        static let warningRedBackground = UIColor.systemRed.withAlphaComponent(0.05)

        /// Warning card border (red tint)
        static let warningRedBorder = UIColor.systemRed.withAlphaComponent(0.2)

        /// Warning card background (orange tint)
        static let warningOrangeBackground = UIColor.systemOrange.withAlphaComponent(0.1)

        /// Warning card border (orange tint)
        static let warningOrangeBorder = UIColor.systemOrange.withAlphaComponent(0.3)

        /// Info card border (blue tint)
        static let infoBlueBorder = UIColor.systemBlue.withAlphaComponent(0.3)
    }

    // MARK: - Layout

    /// Layout constants
    enum Layout {
        /// Default corner radius
        static let defaultCornerRadius: CGFloat = 12

        /// Medium corner radius
        static let mediumCornerRadius: CGFloat = 10

        /// Small corner radius
        static let smallCornerRadius: CGFloat = 8

        /// Cell corner radius
        static let cellCornerRadius: CGFloat = 6

        /// Large corner radius
        static let largeCornerRadius: CGFloat = 16

        /// Default border width
        static let defaultBorderWidth: CGFloat = 1

        /// Thick border width
        static let thickBorderWidth: CGFloat = 2

        /// Default horizontal padding
        static let defaultHorizontalPadding: CGFloat = 16

        /// Default vertical spacing
        static let defaultVerticalSpacing: CGFloat = 16

        /// Small spacing
        static let smallSpacing: CGFloat = 8

        /// Large spacing
        static let largeSpacing: CGFloat = 20

        /// Card padding
        static let cardPadding: CGFloat = 12

        /// Button height
        static let buttonHeight: CGFloat = 44

        /// Input field height
        static let inputFieldHeight: CGFloat = 40
    }

    // MARK: - Fonts

    /// Font constants
    enum Fonts {
        // MARK: - Title Fonts
        /// Hero title (40pt bold) - Home screen app name
        static let hero = UIFont.systemFont(ofSize: 40, weight: .bold)

        /// Extra large title (28pt bold)
        static let extraLargeTitle = UIFont.systemFont(ofSize: 28, weight: .bold)

        /// Large title (22pt heavy) - Context title
        static let largeTitleHeavy = UIFont.systemFont(ofSize: 22, weight: .heavy)

        /// Large title font (20pt bold)
        static let largeTitle = UIFont.systemFont(ofSize: 20, weight: .bold)

        /// Large title semibold (20pt semibold)
        static let largeTitleSemibold = UIFont.systemFont(ofSize: 20, weight: .semibold)

        /// Large title thin (18pt thin) - Splash subtitle
        static let largeTitleThin = UIFont.systemFont(ofSize: 18, weight: .thin)

        /// Title font (17pt semibold)
        static let title = UIFont.systemFont(ofSize: 17, weight: .semibold)

        /// Title medium (17pt medium)
        static let titleMedium = UIFont.systemFont(ofSize: 17, weight: .medium)

        // MARK: - Body Fonts
        /// Body large (18pt semibold)
        static let bodyLargeSemibold = UIFont.systemFont(ofSize: 18, weight: .semibold)

        /// Body font (16pt regular)
        static let body = UIFont.systemFont(ofSize: 16)

        /// Body semibold (16pt semibold)
        static let bodySemibold = UIFont.systemFont(ofSize: 16, weight: .semibold)

        /// Body medium (16pt medium)
        static let bodyMedium = UIFont.systemFont(ofSize: 16, weight: .medium)

        /// Subtitle font (15pt semibold)
        static let subtitle = UIFont.systemFont(ofSize: 15, weight: .semibold)

        /// Subtitle medium (15pt medium)
        static let subtitleMedium = UIFont.systemFont(ofSize: 15, weight: .medium)

        /// Subtitle regular (15pt regular)
        static let subtitleRegular = UIFont.systemFont(ofSize: 15)

        // MARK: - Small Fonts
        /// Caption (14pt medium)
        static let captionMedium = UIFont.systemFont(ofSize: 14, weight: .medium)

        /// Caption regular (14pt regular)
        static let caption = UIFont.systemFont(ofSize: 14)

        /// Caption bold (14pt bold)
        static let captionBold = UIFont.systemFont(ofSize: 14, weight: .bold)

        /// Small font (13pt regular)
        static let small = UIFont.systemFont(ofSize: 13)

        /// Small semibold (13pt semibold)
        static let smallSemibold = UIFont.systemFont(ofSize: 13, weight: .semibold)

        /// Footnote (12pt regular)
        static let footnote = UIFont.systemFont(ofSize: 12)

        /// Footnote semibold (12pt semibold)
        static let footnoteSemibold = UIFont.systemFont(ofSize: 12, weight: .semibold)

        /// Mini (11pt semibold)
        static let miniSemibold = UIFont.systemFont(ofSize: 11, weight: .semibold)

        /// Tiny (10pt semibold) - Tags
        static let tinySemibold = UIFont.systemFont(ofSize: 10, weight: .semibold)

        /// Micro (9pt bold)
        static let microBold = UIFont.systemFont(ofSize: 9, weight: .bold)

        /// Tiny (8pt regular) - Position labels
        static let tiny = UIFont.systemFont(ofSize: 8)

        // MARK: - Icon Fonts
        /// Icon large (28pt)
        static let iconLarge = UIFont.systemFont(ofSize: 28)

        /// Icon medium (24pt)
        static let iconMedium = UIFont.systemFont(ofSize: 24)

        /// Icon regular (22pt)
        static let icon = UIFont.systemFont(ofSize: 22)

        // MARK: - Monospaced Fonts
        /// Monospaced digit font (16pt medium)
        static let monospaced = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .medium)

        /// Monospaced digit regular (16pt regular)
        static let monospacedRegular = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)

        /// Monospaced digit bold (16pt bold)
        static let monospacedBold = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .bold)

        /// Monospaced large (20pt semibold)
        static let monospacedLarge = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .semibold)

        /// Monospaced code (17pt medium) - Code display
        static let monospacedCode = UIFont(name: "Menlo-Bold", size: 17) ?? UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .medium)

        /// Monospaced bold font (24pt)
        static let monoBold = UIFont(name: "Courier-Bold", size: 24) ?? UIFont.boldSystemFont(ofSize: 24)

        // MARK: - Special Fonts
        /// Arrow font (30pt bold)
        static let arrow = UIFont.systemFont(ofSize: 30, weight: .bold)

        /// Manual normal (15pt)
        static let manualBody = UIFont.systemFont(ofSize: 15)

        /// Manual title (20pt bold)
        static let manualTitle = UIFont.boldSystemFont(ofSize: 20)
    }

    // MARK: - Shadows

    /// Shadow styles
    enum Shadow {
        /// Card shadow configuration
        static func applyCardShadow(to view: UIView) {
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOffset = CGSize(width: 0, height: 2)
            view.layer.shadowOpacity = 0.1
            view.layer.shadowRadius = 4
        }
    }

    enum MinimalTheme {

        // MARK: Colors

        /// Background color #F5F5F7 (Apple website light gray)
        static let background = UIColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1.0)

        /// Card background color #FFFFFF (pure white)
        static let cardBackground = UIColor.white

        /// Secondary background color #FAFAFA (very light gray, for input fields etc.)
        static let secondaryBackground = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)

        /// Primary text color #1D1D1F (dark gray black)
        static let textPrimary = UIColor(red: 0.114, green: 0.114, blue: 0.122, alpha: 1.0)

        /// Secondary text color #86868B (medium gray)
        static let textSecondary = UIColor(red: 0.525, green: 0.525, blue: 0.545, alpha: 1.0)

        /// Placeholder text color #C7C7CC (light gray)
        static let textPlaceholder = UIColor(red: 0.78, green: 0.78, blue: 0.8, alpha: 1.0)

        /// Accent color #007AFF (iOS standard blue)
        static let accent = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)

        /// Success color #34C759 (iOS green)
        static let success = UIColor(red: 0.204, green: 0.78, blue: 0.349, alpha: 1.0)

        /// Warning color #C78540 (soft amber orange - warm reminder)
        static let warning = UIColor(red: 0.78, green: 0.52, blue: 0.25, alpha: 1.0)

        /// Stable color #002B5B (elegant deep blue - expresses stability, eternity, power of immutability)
        static let stable = UIColor(red: 0.0, green: 0.169, blue: 0.357, alpha: 1.0)

        /// Border color #E0E0E5 (light gray border - softer than before)
        static let border = UIColor(red: 0.878, green: 0.878, blue: 0.898, alpha: 1.0)

        /// Separator color #E5E5EA (very light gray)
        static let separator = UIColor(red: 0.898, green: 0.898, blue: 0.918, alpha: 1.0)

        // MARK: Fonts

        /// Title font - SF Pro Display Semibold 20pt
        static let titleFont = UIFont.systemFont(ofSize: 20, weight: .semibold)

        /// Body font - SF Pro Text Regular 16pt
        static let bodyFont = UIFont.systemFont(ofSize: 16, weight: .regular)

        /// Digit font - SF Mono Medium 16pt
        static let digitFont = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .medium)

        /// Small font - SF Pro Text Regular 14pt
        static let smallFont = UIFont.systemFont(ofSize: 14, weight: .regular)

        /// Button font - SF Pro Text Semibold 17pt
        static let buttonFont = UIFont.systemFont(ofSize: 17, weight: .semibold)

        // MARK: Layout

        /// Corner radius - unified 12pt
        static let cornerRadius: CGFloat = 12

        /// Border width
        static let borderWidth: CGFloat = 0.5

        /// Card padding
        static let cardPadding: CGFloat = 16

        /// Element spacing
        static let spacing: CGFloat = 12

        // MARK: Effects

        /// Apply card shadow (very subtle)
        static func applyCardShadow(to view: UIView) {
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOffset = CGSize(width: 0, height: 2)
            view.layer.shadowOpacity = 0.05
            view.layer.shadowRadius = 8
            view.layer.masksToBounds = false
        }

        /// Apply button shadow (subtle)
        static func applyButtonShadow(to view: UIView) {
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOffset = CGSize(width: 0, height: 4)
            view.layer.shadowOpacity = 0.1
            view.layer.shadowRadius = 12
            view.layer.masksToBounds = false
        }

        /// Apply thin border
        static func applyBorder(to view: UIView) {
            view.layer.borderColor = border.cgColor
            view.layer.borderWidth = borderWidth
            view.layer.cornerRadius = cornerRadius
        }

        /// Create simple gradient (for buttons)
        static func createSimpleGradient() -> CAGradientLayer {
            let gradient = CAGradientLayer()
            gradient.colors = [
                accent.cgColor,
                accent.withAlphaComponent(0.9).cgColor
            ]
            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint = CGPoint(x: 1, y: 1)
            return gradient
        }
    }

}

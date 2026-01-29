//
//  AlertHelper.swift
//  WujiSeed
//
//  Standardized error alerts and warning dialogs
//

import UIKit

/// Standardized Alert configuration
struct StandardAlert {
    let title: String
    let message: String
    let errorCode: String?
    let style: UIAlertController.Style

    /// Create standard error Alert
    /// - Parameters:
    ///   - title: Title
    ///   - message: Detailed message
    ///   - errorCode: Error code (optional, for debugging)
    ///   - style: Alert style, default .alert
    init(title: String, message: String, errorCode: String? = nil, style: UIAlertController.Style = .alert) {
        self.title = title
        self.message = message
        self.errorCode = errorCode
        self.style = style
    }

    /// Create full message with error code
    var fullMessage: String {
        if let code = errorCode {
            return "\(message)\n\nError code: \(code)"
        }
        return message
    }
}

/// UIViewController extension: Standardized Alert display
extension UIViewController {

    /// Show standard error alert
    /// - Parameters:
    ///   - alert: StandardAlert configuration
    ///   - actions: Custom action buttons (optional)
    ///   - completion: Completion callback (optional)
    func showStandardAlert(
        _ alert: StandardAlert,
        actions: [UIAlertAction]? = nil,
        completion: (() -> Void)? = nil
    ) {
        let alertController = UIAlertController(
            title: alert.title,
            message: alert.fullMessage,
            preferredStyle: alert.style
        )

        // If custom actions provided, use custom actions
        if let customActions = actions, !customActions.isEmpty {
            for action in customActions {
                alertController.addAction(action)
            }
        } else {
            // Otherwise add default "OK" button
            let okAction = UIAlertAction(
                title: Lang("common.done"),
                style: .default,
                handler: { _ in completion?() }
            )
            alertController.addAction(okAction)
        }

        present(alertController, animated: true)
    }

    /// Show coordinate format error alert (with supported formats list)
    /// - Parameter errorCode: Error code
    func showCoordinateFormatError(errorCode: String = "COORD_001") {
        let alert = StandardAlert(
            title: Lang("error.coord_format_title"),
            message: Lang("error.coord_format_message"),
            errorCode: errorCode
        )

        let okAction = UIAlertAction(
            title: Lang("common.done"),
            style: .default
        )

        showStandardAlert(alert, actions: [okAction])
    }

    /// Show coordinate range error alert
    /// - Parameters:
    ///   - lat: Latitude value (optional)
    ///   - lon: Longitude value (optional)
    ///   - errorCode: Error code
    func showCoordinateRangeError(lat: Double? = nil, lon: Double? = nil, errorCode: String = "COORD_002") {
        var message = Lang("error.coord_range_message")

        if let latitude = lat {
            message += "\n\nCurrent latitude: \(latitude)"
        }
        if let longitude = lon {
            message += "\nCurrent longitude: \(longitude)"
        }

        let alert = StandardAlert(
            title: Lang("error.coord_range_title"),
            message: message,
            errorCode: errorCode
        )

        showStandardAlert(alert)
    }

    /// Show coordinate precision insufficient error
    /// - Parameter errorCode: Error code
    func showCoordinatePrecisionError(errorCode: String = "COORD_003") {
        let alert = StandardAlert(
            title: Lang("error.coord_precision_title"),
            message: Lang("error.coord_precision_message"),
            errorCode: errorCode
        )

        showStandardAlert(alert)
    }

    /// Show generic error alert
    /// - Parameters:
    ///   - title: Title
    ///   - message: Message
    ///   - errorCode: Error code
    ///   - completion: Completion callback
    func showError(
        title: String,
        message: String,
        errorCode: String? = nil,
        completion: (() -> Void)? = nil
    ) {
        let alert = StandardAlert(
            title: title,
            message: message,
            errorCode: errorCode
        )

        showStandardAlert(alert, completion: completion)
    }
}

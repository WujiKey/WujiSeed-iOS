//
//  WujiLogger.swift
//  WujiKey
//
//  Unified logging utility with conditional compilation support
//

import Foundation

/// WujiKey unified logging utility
enum WujiLogger {

    /// Log level
    enum Level: String {
        case debug = "🔍"
        case info = "ℹ️"
        case success = "✅"
        case warning = "⚠️"
        case error = "❌"
    }

    /// Output debug log (only in DEBUG mode)
    /// - Parameters:
    ///   - items: Content to output
    ///   - level: Log level
    ///   - file: File name
    ///   - function: Function name
    ///   - line: Line number
    static func debug(
        _ items: Any...,
        level: Level = .debug,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .none,
            timeStyle: .medium
        )
        let message = items.map { "\($0)" }.joined(separator: " ")
        print("\(level.rawValue) [\(timestamp)] [\(fileName):\(line)] \(function) - \(message)")
        #endif
    }

    /// Output info log (only in DEBUG mode)
    static func info(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let message = items.map { "\($0)" }.joined(separator: " ")
        print("ℹ️ [\(fileName):\(line)] \(message)")
        #endif
    }

    /// Output success log (only in DEBUG mode)
    static func success(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let message = items.map { "\($0)" }.joined(separator: " ")
        print("✅ [\(fileName):\(line)] \(message)")
        #endif
    }

    /// Output warning log (only in DEBUG mode)
    static func warning(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let message = items.map { "\($0)" }.joined(separator: " ")
        print("⚠️ [\(fileName):\(line)] \(message)")
        #endif
    }

    /// Output error log (only in DEBUG mode)
    static func error(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let message = items.map { "\($0)" }.joined(separator: " ")
        print("❌ [\(fileName):\(line)] \(message)")
        #endif
    }

    /// Output separator line (only in DEBUG mode)
    static func separator(length: Int = 60, char: Character = "=") {
        #if DEBUG
        print(String(repeating: char, count: length))
        #endif
    }

    /// Output formatted debug block (only in DEBUG mode)
    static func debugBlock(title: String, body: () -> Void) {
        #if DEBUG
        separator()
        print("🔍 \(title)")
        separator()
        body()
        separator()
        #endif
    }
}

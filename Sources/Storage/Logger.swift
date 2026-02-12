//
//  Loggers.swift
//  Storage
//
//  Created by Татьяна Макеева on 04.01.2025.
//

public enum LogLevel: String {
    case debug
    case info
    case warning
    case error
}

public enum LogMessageType: String {
    case yandex
    case localFilestorage
    case google
    case archive
}

public protocol Logger: Sendable {
    func log(
        _ message: String,
        level: LogLevel,
        type: LogMessageType,
        file: String,
        function: String,
        line: Int
    )
}

extension Logger {
    public func debug(
        _ message: String,
        type: LogMessageType,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, type: type, file: file, function: function, line: line)
    }

    public func info(
        _ message: String,
        type: LogMessageType,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, type: type, file: file, function: function, line: line)
    }

    public func warning(
        _ message: String,
        type: LogMessageType,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, type: type, file: file, function: function, line: line)
    }

    public func error(
        _ message: String,
        type: LogMessageType,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, type: type, file: file, function: function, line: line)
    }

    public func error(
        _ error: Error,
        type: LogMessageType,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(error.localizedDescription, level: .error, type: type, file: file, function: function, line: line)
    }
}

/*
 * @file KSCommand.swift
 * @description Define KSCommand
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import Foundation

public struct KSCommand {
        public var commandPath:         String
        public var arguments:           Array<String>

        public init(commandPath path: String, arguments args: Array<String>) {
                commandPath     = path
                arguments       = args
        }

        public var description: String { get {
                return "command(\(commandPath), [\(arguments)])"
        }}
}


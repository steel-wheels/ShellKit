/*
 * @file KSCommand.swift
 * @description Define KSCommand
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import Foundation

public struct KSExecCommand {
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

public enum KSCommandLine
{
        case exec(KSExecCommand)

        public var description: String { get {
                let result: String
                switch self {
                case .exec(let ecmd):
                        result = ecmd.description
                }
                return result
        }}
}


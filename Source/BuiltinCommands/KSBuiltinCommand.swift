/*
 * @file KSBuiltinCommand.swift
 * @description Define KSBuiltinCommand class
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import MultiDataKit
import JavaScriptKit
import JavaScriptCore
import Foundation
import UniformTypeIdentifiers

public enum KSBuiltinCommand {
        case printEnvCommand
        case runCommand
        case whichCommand

        public static var allCommands: Array<KSBuiltinCommand> { get {
                return [
                        .printEnvCommand,
                        .runCommand,
                        .whichCommand
                ]
        }}

        public var commandName: String { get {
                let result: String
                switch self {
                case .printEnvCommand:  result = "printenv"
                case .runCommand:       result = "run"
                case .whichCommand:     result = "which"
                }
                return result
        }}

        public var executableURL: URL? {
                guard let resdir = FileManager.default.resourceDirectory(forClass: KSShell.self) else {
                        NSLog("[Error] Failed to get resource directory for KSShell class")
                        return nil
                }
                let subpath: String = "Script/" + self.commandName + ".js"
                return resdir.appendingPathComponent(subpath, conformingTo: .javaScript)
        }

        static public func decodeByName(commandPath path: String) -> KSBuiltinCommand? {
                for cmd in KSBuiltinCommand.allCommands {
                        if cmd.commandName == path {
                                return cmd
                        }
                }
                return nil
        }
}


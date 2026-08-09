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

public enum KSBuiltinCommandName: String {
        case printEnvCommand    = "printenv"
        case runCommand         = "run"
        case whichCommand       = "which"

        static public func decodeByName(commandPath path: String) -> KSBuiltinCommandName? {
                return KSBuiltinCommandName(rawValue: path)
        }
}


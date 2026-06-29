/*
 * @file KSEnvVaraibels.swift
 * @description Extend MIEnvVariables class
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public enum KSShellMode: Int {
        public static let CommandString = "command"
        public static let ScriptSString = "script"

        case command    = 0
        case script     = 1

        public func toString() -> String {
                let result: String
                switch self {
                case .command:  result  = KSShellMode.CommandString
                case .script:   result  = KSShellMode.ScriptSString
                }
                return result
        }
}

extension MIEnvVariables
{
        private static let shellMode    = "SHELLMODE"

        public func shellMode() -> KSShellMode {
                if let val = self.intValue(forKey: MIEnvVariables.shellMode) {
                        if let mode = KSShellMode(rawValue: val) {
                                return mode
                        }
                }
                return .command
        }

        public func set(shellMode mode: KSShellMode){
                self.set(intValue: mode.rawValue, forKey: MIEnvVariables.shellMode)
        }
}

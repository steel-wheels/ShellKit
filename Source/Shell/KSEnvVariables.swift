/*
 * @file KSEnvVaraibels.swift
 * @description Extend MIEnvVariables class
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public enum KSShellMode: Int {
        case shell      = 0
        case script     = 1
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
                return .shell
        }

        public func set(shellMode mode: KSShellMode){
                self.set(intValue: mode.rawValue, forKey: MIEnvVariables.shellMode)
        }
}

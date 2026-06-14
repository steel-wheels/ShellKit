/*
 * @file KSPreference.swift
 * @description Define MIPreference
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class KSPreference
{
        public var homeDirectory:       URL
        public var foregroundColor:     MITextColor
        public var backgroundColor:     MITextColor

        public init() {
                self.homeDirectory      = URL(fileURLWithPath: NSHomeDirectory())
                self.foregroundColor    = .green
                self.backgroundColor    = .black
        }

        public func load() {
        }
}

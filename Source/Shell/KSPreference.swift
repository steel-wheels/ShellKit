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
        public var foregroundColor:     MITextColor
        public var backgroundColor:     MITextColor

        public init() {
                self.foregroundColor    = .green(true)
                self.backgroundColor    = .black(false)
        }

        public func load() {
        }
}

/*
 * @file KSPrompt.swift
 * @description Define MIPrompt
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import Foundation

public class KSPrompt
{
        private var mPrompt: String

        public var string: String { get { return mPrompt }}

        public init() {
                mPrompt = "% "
        }
}

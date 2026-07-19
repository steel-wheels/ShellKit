/*
 * @file KSShellExtension.swift
 * @description Define extension function
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import MultiDataKit
import Foundation

open class KSShellExtension
{
        public enum FileType {
                case file
                case directory
        }

        public init() {
        }

        open var doesSupportFileSelector: Bool { get {
                return false
        }}

        open func selectFile(title tstr: String, fileType file: FileType, extension estr: String) -> URL? {
                return nil
        }
}

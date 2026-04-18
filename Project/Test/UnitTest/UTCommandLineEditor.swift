/*
 * @file UTCommandLineEditor.swift
 * @description Test function for KSCommandLineEditor
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import ShellKit
import Foundation

public func testCommandLineEditor() -> Bool
{
        let lineedit = KSCommandLineEditor()
        NSLog("init line: \(lineedit.debugString)")

        lineedit.put(string: "abcd")
        NSLog("put line: \(lineedit.debugString)")

        let r0 = lineedit.moveCursorBackward(offset: 2)
        NSLog("\(r0): moveBack line: \(lineedit.debugString)")

        let r1 = lineedit.deleteBackward(length: 1)
        NSLog("\(r1): delBack line: \(lineedit.debugString)")

        let r2 = lineedit.deleteForward(length: 1)
        NSLog("\(r2): delFor line: \(lineedit.debugString)")

        let r3 = lineedit.moveCursorForward(offset: 1)
        NSLog("\(r3): moveFor \(lineedit.debugString)")

        return true
}

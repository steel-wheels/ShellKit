/*
 * @file UTCommandLineEditor.swift
 * @description Test function for KSCommandLineEditor
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import ShellKit
import MultiDataKit
import Foundation

public func testCommandLineEditor() -> Bool
{
        let res0 = testOneCommand()
        let res1 = testSequence()
        return res0 && res1
}

private func testOneCommand() -> Bool
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

private func testSequence() -> Bool
{
        let result = true

        let ecodes: Array<MIEscapeCode> = [
                .string("abcde"),
                .key(.delete),
                .key(.arrow(.left)),
                .key(.arrow(.right)),
                .moveCursorBackward(10),
                .moveCursorForward(10),
                .moveCursorBackward(2),
                .eraceFromCursorWithLength(1),
                .eraceFromCusorToEndOfLine,
                .string("CDE"),
                .moveCursorBackward(3),
                .eraceStartOfLineToCursor
        ]

        let lineedit = KSCommandLineEditor()
        for ecode in ecodes {
                let rcodes = lineedit.exec(escapeCode: ecode)
                print(ecode.description() + ":")
                print(" = " + lineedit.debugString)
                for rcode in rcodes {
                        print("  -> " + rcode.description())
                }
        }

        return result
}


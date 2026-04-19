/*
 * @file KSReadLine.swift
 * @description Define MIReadLine
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class KSReadLine
{
        public enum Command {
                case execute(String)
                case showHistory(Bool)                 // true: up, false: down
                case escapeCode(MIEscapeCode)
        }

        private var mInputFileHandle:   FileHandle
        private var mOutputFileHandle:  FileHandle
        private var mErrorFileHandle:   FileHandle

        private var mLineEditor:        KSCommandLineEditor

        public init(input infile: FileHandle, output outfile: FileHandle, error errfile: FileHandle) {
                mInputFileHandle        = infile
                mOutputFileHandle       = outfile
                mErrorFileHandle        = errfile
                mLineEditor             = KSCommandLineEditor()
        }

        public func decodeCodes(edcapeCodes ecodes: Array<MIEscapeCode>) -> Array<Command> {
                var result: Array<Command> = []
                for ecode in ecodes {
                        let rcodes = decodeCode(edcapeCode: ecode)
                        result.append(contentsOf: rcodes)
                }
                return result
        }

        private func decodeCode(edcapeCode srccode: MIEscapeCode) -> Array<Command> {
                var result: Array<Command> = []
                let ecodes = mLineEditor.exec(escapeCode: srccode)
                for ecode in ecodes {
                        switch ecode {
                        case .key(let key):
                                switch key {
                                case .arrow(let atype):
                                        switch atype {
                                        case .up:   result.append(.showHistory(true))
                                        case .down: result.append(.showHistory(false))
                                        default:
                                                result.append(.escapeCode(ecode))
                                        }
                                case .carriageReturn, .lineFeed, .newline:
                                        let cmd = mLineEditor.string
                                        mLineEditor.clear()
                                        result.append(.escapeCode(ecode))
                                        result.append(.execute(cmd))
                                default:
                                        result.append(.escapeCode(ecode))
                                }
                        default:
                                result.append(.escapeCode(ecode))
                        }
                }
                return result
        }
}

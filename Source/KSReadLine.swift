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
        private var mInputFileHandle:   FileHandle
        private var mOutputFileHandle:  FileHandle
        private var mErrorFileHandle:   FileHandle
        private var mCurrentPosition:   String.Index
        private var mCurrentLine:       String

        private var mCommands:                  Array<String>

        public init(input infile: FileHandle, output outfile: FileHandle, error errfile: FileHandle) {
                mInputFileHandle        = infile
                mOutputFileHandle       = outfile
                mErrorFileHandle        = errfile
                mCurrentLine            = ""
                mCurrentPosition        = mCurrentLine.startIndex
                mCommands               = []
        }

        public func decodeCodes(edcapeCodes ecodes: Array<MIEscapeCode>) -> Array<MIEscapeCode> {
                var result: Array<MIEscapeCode> = []
                for ecode in ecodes {
                        let rcodes = decodeCode(edcapeCode: ecode)
                        result.append(contentsOf: rcodes)
                }
                return result
        }

        private func decodeCode(edcapeCode ecode: MIEscapeCode) -> Array<MIEscapeCode> {
                var result: Array<MIEscapeCode> = []

                switch ecode {
                case .insertString(let str):
                        let len = str.lengthOfBytes(using: .utf8)
                        mCurrentLine.insert(contentsOf: str, at: mCurrentPosition)
                        let _ = moveCursorForward(offset: len)
                        result.append(.insertString(str))
                case .arrowKey(let key):
                        switch key {
                          case .up:
                                showHistory(up: true)
                          case .down:
                                showHistory(up: false)
                          case .left:
                                let len = moveCursorBackward(offset: 1)
                                if len > 0 {
                                        result.append(.moveCursorBackward(len))
                                }
                          case .right:
                                let len = moveCursorForward(offset: 1)
                                if len > 0 {
                                        result.append(.moveCursorForward(len))
                                }
                          @unknown default:
                                mErrorFileHandle.write(string: "[Error] Can not happen at \(#file)")
                        }
                case .deleteKey:
                        result.append(.moveCursorBackward(1))
                        result.append(.eraceFromCursorWithLength(1))
                case .newlineKey:
                        if !mCurrentLine.isEmpty {
                                /* move cursor to end of line */
                                var off = 0
                                while mCurrentPosition < mCurrentLine.endIndex {
                                        mCurrentPosition = mCurrentLine.index(after: mCurrentPosition)
                                        off += 1
                                }
                                result.append(.moveCursorForward(off))
                                result.append(.newlineKey)

                                /* push the command to execute later */
                                mCommands.append(mCurrentLine)

                                /* clear current command line */
                                mCurrentLine     = ""
                                mCurrentPosition = mCurrentLine.startIndex
                        }
                case .moveCursorForward(_), .moveCursorBackward(_):
                        result.append(ecode)
                default:
                        mErrorFileHandle.write(string: "ShellKit: Ununkown code: \(ecode.description())")
                }
                return result
        }

        public func popCommands() -> Array<String> {
                let cmds  = mCommands
                mCommands = []
                return cmds
        }

        private func showHistory(up doup: Bool) {
                mErrorFileHandle.write(string: "Show history: \(doup)")
        }

        private func moveCursorForward(offset off: Int) -> Int {
                var result = 0
                for _ in 0..<off {
                        if mCurrentPosition < mCurrentLine.endIndex {
                                mCurrentPosition = mCurrentLine.index(after: mCurrentPosition)
                                result += 1
                        } else {
                                break
                        }
                }
                return result
        }

        private func moveCursorBackward(offset off: Int) -> Int {
                var result = 0
                for _ in 0..<off {
                        if mCurrentLine.startIndex < mCurrentPosition {
                                mCurrentPosition = mCurrentLine.index(before: mCurrentPosition)
                                result += 1
                        } else {
                                break
                        }
                }
                return result
        }
}

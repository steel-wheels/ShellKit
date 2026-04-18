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
        private var mCurrentPosition:   String.Index
        private var mCurrentLine:       String

        public init(input infile: FileHandle, output outfile: FileHandle, error errfile: FileHandle) {
                mInputFileHandle        = infile
                mOutputFileHandle       = outfile
                mErrorFileHandle        = errfile
                mCurrentLine            = ""
                mCurrentPosition        = mCurrentLine.startIndex
        }

        public func decodeCodes(edcapeCodes ecodes: Array<MIEscapeCode>) -> Array<Command> {
                var result: Array<Command> = []
                for ecode in ecodes {
                        let rcodes = decodeCode(edcapeCode: ecode)
                        result.append(contentsOf: rcodes)
                }
                return result
        }

        private func decodeCode(edcapeCode ecode: MIEscapeCode) -> Array<Command> {
                var result: Array<Command> = []

                switch ecode {
                case .string(let str):
                        let len = str.lengthOfBytes(using: .utf8)
                        mCurrentLine.insert(contentsOf: str, at: mCurrentPosition)
                        let _ = moveCursorForward(offset: len)
                        result.append(.escapeCode(.string(str)))
                case .moveCursorForward(_), .moveCursorBackward(_):
                        result.append(.escapeCode(ecode))
                case .key(let key):
                        switch(key) {
                        case .delete:
                                result.append(.escapeCode(.moveCursorBackward(1)))
                                result.append(.escapeCode(.eraceFromCursorWithLength(1)))
                        case .arrow(let atype):
                                switch atype {
                                  case .up:
                                        result.append(.showHistory(true))
                                  case .down:
                                        result.append(.showHistory(false))
                                  case .left:
                                        let len = moveCursorBackward(offset: 1)
                                        if len > 0 {
                                                result.append(.escapeCode(.moveCursorBackward(len)))
                                        }
                                  case .right:
                                        let len = moveCursorForward(offset: 1)
                                        if len > 0 {
                                                result.append(.escapeCode(.moveCursorForward(len)))
                                        }
                                  @unknown default:
                                        mErrorFileHandle.write(string: "[Error] Can not happen at \(#file)")
                                }
                        case .carriageReturn, .lineFeed, .newline:
                                /* move cursor to end of line */
                                var off = 0
                                while mCurrentPosition < mCurrentLine.endIndex {
                                        mCurrentPosition = mCurrentLine.index(after: mCurrentPosition)
                                        off += 1
                                }
                                if off > 0 {
                                        result.append(.escapeCode(.moveCursorForward(off)))
                                }
                                result.append(.escapeCode(.string("\n")))

                                if !mCurrentLine.isEmpty {
                                        /* push the command to execute later */
                                        result.append(.execute(mCurrentLine))

                                        /* clear current command line */
                                        mCurrentLine     = ""
                                        mCurrentPosition = mCurrentLine.startIndex
                                }
                        default:
                                mErrorFileHandle.write(string: "ShellKit: Unsuppoted key: \(key.description)")
                        }
                default:
                        mErrorFileHandle.write(string: "ShellKit: Ununkown code: \(ecode.description())")
                }
                return result
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

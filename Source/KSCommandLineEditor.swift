/*
 * @file KSCommandLineEditor.swift
 * @description Define MILineEditor
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class KSCommandLineEditor
{
        private var mString:    String
        private var mIndex:     String.Index

        public init() {
                mString = ""
                mIndex  = mString.startIndex
        }

        public var string: String { get {
                return mString
        }}

        public var indexPosition: Int {
                var result = 0
                var idx    = mString.startIndex
                while idx < mIndex {
                        result += 1
                        idx = mString.index(after: idx)
                }
                return result
        }

        public var debugString: String { get {
                var result: String = ""
                var idx    = mString.startIndex
                let endidx = mString.endIndex

                while idx < endidx {
                        if mIndex == idx {
                                result += "*"
                        }
                        result += String(mString[idx])
                        idx = mString.index(after: idx)
                }
                if mIndex == endidx {
                        result += "*"
                }
                return result
        }}

        public func clear() {
                mString = ""
                mIndex  = mString.startIndex
        }

        public func put(string str: String) {
                mString.insert(contentsOf: str, at: mIndex)
                let _ = moveCursorForward(offset: str.lengthOfBytes(using: .utf8))
        }

        public func deleteBackward(length len: Int) -> Int {
                guard len > 0 else {
                        return 0
                }
                if let previdx = prevIndex() {
                        mString.remove(at: previdx)
                        mIndex = previdx
                        return deleteBackward(length: len - 1) + 1
                } else {
                        return 0
                }
        }

        public func deleteForward(length len: Int) -> Int {
                guard len > 0 else {
                        return 0
                }
                if mIndex < mString.endIndex {
                        mString.remove(at: mIndex)
                        return deleteForward(length: len - 1) + 1
                } else {
                        return 0
                }
        }

        public func moveCursorForward(offset off: Int) -> Int {
                for i in 0..<off {
                        if let nxtidx = nextIndex() {
                                mIndex = nxtidx
                        } else {
                                return i
                        }
                }
                return off
        }

        public func moveCursorBackward(offset off: Int) -> Int {
                for i in 0..<off {
                        if let previdx = prevIndex() {
                                mIndex = previdx
                        } else {
                                return i
                        }
                }
                return off
        }

        private func nextIndex() -> String.Index? {
                if mIndex < mString.endIndex {
                        return mString.index(after: mIndex)
                }
                return nil
        }

        private func prevIndex() -> String.Index? {
                if mString.startIndex < mIndex {
                        return mString.index(before: mIndex)
                } else {
                        return nil
                }
        }

        public func exec(escapeCode ecode: MIEscapeCode) -> Array<MIEscapeCode> {
                var result: Array<MIEscapeCode> = []
                switch ecode {
                case .string(let str):
                        self.put(string: str)
                        result.append(ecode)
                case .key(let key):
                        switch key {
                        case .arrow(let atype):
                                switch atype {
                                case .up, .down:
                                        result.append(ecode)
                                case .right:
                                        if let rcode = execMoveCursorForward(offset: 1) {
                                                result.append(rcode)
                                        }
                                case .left:
                                        if let rcode = execMoveCursorbackward(offset: 1) {
                                                result.append(rcode)
                                        }
                                @unknown default:
                                        NSLog("[Error] Unknown arrow key at \(#file)")
                                }
                        case .backspace, .delete:
                                let rcodes = execDeleteBackward(offset: 1)
                                result.append(contentsOf: rcodes)
                        case .carriageReturn, .lineFeed, .enter, .newline, .function(_),
                                        .formFeed, .help, .home, .insert, .menu,
                                        .pageUp, .pageDown, .tab, .command(_), .control(_):
                                result.append(ecode)
                        @unknown default:
                                NSLog("[Error] Unknown key at \(#file)")
                        }
                case .moveCursorForward(let off):
                        if let rcode = execMoveCursorForward(offset: off) {
                                result.append(rcode)
                        }
                case .moveCursorBackward(let off):
                        if let rcode = execMoveCursorbackward(offset: off) {
                                result.append(rcode)
                        }
                case .eraceFromCursorWithLength(let len):
                        let off = deleteForward(length: len)
                        if off > 0 {
                                result.append(.eraceFromCursorWithLength(off))
                        }
                case .eraceStartOfLineToCursor:
                        let startidx = mString.startIndex
                        if startidx < mIndex {
                                let offset = indexPosition
                                mString.removeSubrange(startidx ..< mIndex)
                                mIndex = mString.startIndex

                                result.append(.moveCursorBackward(offset))
                                result.append(.eraceFromCursorWithLength(offset))
                        }
                case .eraceFromCusorToEndOfLine:
                        let len = mString.lengthOfBytes(using: .utf8)
                        let off = deleteForward(length: len)
                        if off > 0 {
                                result.append(.eraceFromCursorWithLength(off))
                        }
                case .eraceEntireLine:
                        let len = mString.lengthOfBytes(using: .utf8)
                        let pos = self.indexPosition
                        result.append(.moveCursorBackward(pos))
                        result.append(.eraceFromCursorWithLength(len))
                        mString = ""
                        mIndex  = mString.startIndex
                case .moveCursorTo(_, _),
                     .moveCursorUp(_),
                     .moveCursor1LineUp,
                     .moveCursorDown(_),
                     .moveCursorToBeginingOfNextLine(_),
                     .moveCursorToBeginingOfPrevLine(_),
                     .moveCursorToColumn(_),
                     .eraceFromCursorUntilEndOfScreen,
                     .eraceFromToBeginningOfScreen,
                     .eraceEntireScreen,
                     .eraceSavedLines,
                     .requestCursorPosition,
                     .setCharacterAttribute(_),
                     .resetAllCharacterAttributes,
                     .setColor(_),
                     .saveCursorPosition(_),
                     .restoreCursorPosition(_),
                     .makeCursorVisible(_),
                     .blinkCursor(_),
                     .saveScreen,
                     .restoreScreen,
                     .enableAlternativeBuffer(_):
                        break
                @unknown default:
                        NSLog("[Error] Unknown ecode at \(#file)")
                }
                return result
        }

        private func execMoveCursorForward(offset off: Int) -> MIEscapeCode? {
                let newoff = moveCursorForward(offset: off)
                if newoff > 0 {
                        return .moveCursorForward(newoff)
                } else {
                        return nil
                }
        }

        private func execMoveCursorbackward(offset off: Int) -> MIEscapeCode? {
                let newoff = moveCursorBackward(offset: off)
                if newoff > 0 {
                        return .moveCursorBackward(newoff)
                } else {
                        return nil
                }
        }

        private func execDeleteBackward(offset off: Int) -> Array<MIEscapeCode> {
                var result: Array<MIEscapeCode> = []
                let off = deleteBackward(length: 1)
                if off > 0 {
                        result.append(.moveCursorBackward(off))
                        result.append(.eraceFromCursorWithLength(off))
                }
                return result
        }
}

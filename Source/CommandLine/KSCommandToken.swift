/*
 * @file KKSCommandToken.swift
 * @description Define KSCommandToken class
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class KSCommandToken
{
        public enum Token {
                case command(String)
                case string(String)
                case pipe               // "|"
        }

        public static func parse(commandLine cmdline: String) -> Result<Array<Token>, NSError> {
                var index      = cmdline.startIndex
                let endindex   = cmdline.endIndex
                var isInString = false
                var result: Array<Token> = []

                var currentString: String = ""
                while index < endindex {
                        let c = cmdline[index]
                        if !isInString {
                                if c.isWhitespace {
                                        if !currentString.isEmpty {
                                                result.append(.command(currentString))
                                        }
                                        currentString = ""
                                } else if c == "\"" {
                                        isInString = true
                                        if !currentString.isEmpty {
                                                result.append(.command(currentString))
                                        }
                                        currentString = ""
                                } else if c == "|" {
                                        isInString = true
                                        if !currentString.isEmpty {
                                                result.append(.command(currentString))
                                        }
                                        currentString = ""
                                        result.append(.pipe)
                                } else {
                                        currentString.append(c)
                                }
                        } else {
                                if c == "\"" {
                                        isInString = false
                                        result.append(.string("\"" + currentString + "\""))
                                        currentString = ""
                                } else {
                                        currentString.append(c)
                                }
                        }
                        index = cmdline.index(after: index)
                }
                if isInString {
                        let err = MIError.parseError(message: "The string is NOT closed by \".", line: 0)
                        return .failure(err)
                }
                if !currentString.isEmpty {
                        result.append(.string(currentString))
                        currentString = ""
                }
                return .success(result)
        }
}


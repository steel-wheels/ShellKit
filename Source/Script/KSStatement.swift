/*
 * @file KSStatement.swift
 * @description Define KSStatement class
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import Foundation

open class KSStatement
{
        public func processIdVariableName(processId pid: Int) -> String {
                return "p\(pid)"
        }

        public func stringValue(string str: String) -> String {
                return "\"" + str + "\""
        }

        public func stringArrayValue(strings strs: Array<String>) -> String {
                var result = "["
                var is1st  = true
                for str in strs {
                        if !is1st { result += ", " }
                        result += stringValue(string: str)
                        is1st  = false
                }
                result += "]"
                return result
        }

        open func encode() -> Array<String> {
                NSLog("[Error] Must be override")
                return []
        }
}

public class KSStatementSequence: KSStatement
{
        private var mStatements:        Array<KSStatement>

        public override init() {
                mStatements     = []
        }

        public func append(contentsOf stmts: Array<KSStatement>) {
                mStatements.append(contentsOf: stmts)
        }

        public override func encode() -> Array<String> {
                var result: Array<String> = []
                for stmt in mStatements {
                        result.append(contentsOf: stmt.encode())
                }
                return result
        }
}

public class KSAllocateProcessStatement: KSStatement
{
        private var mProcessId:         Int
        private var mCommandPath:       String
        private var mArguments:         Array<String>

        public init(processId pid:Int, commandPath path: String, arguments args: Array<String>) {
                mProcessId      = pid
                mCommandPath    = path
                mArguments      = args
        }

        public override func encode() -> Array<String> {
                var line = "let "
                line += processIdVariableName(processId: mProcessId)
                line += " = newProcess("
                line += stringValue(string: mCommandPath)
                line += ", "
                line += stringArrayValue(strings: mArguments)
                line += ") ;"
                return [line]
        }
}

public class KSRunProcessStatement: KSStatement
{
        private var mProcessId:         Int

        public init(processId pid: Int) {
                mProcessId      = pid
        }

        public override func encode() -> Array<String> {
                var line = processIdVariableName(processId: mProcessId)
                line += ".run() ;"
                return [line]
        }
}

public class KSWaitProcessStatement: KSStatement
{
        private var mProcessId:         Int

        public init(processId pid: Int) {
                mProcessId      = pid
        }

        public override func encode() -> Array<String> {
                var line = processIdVariableName(processId: mProcessId)
                line += ".wait() ;"
                return [line]
        }
}


/*
 * @file KSStatement.swift
 * @description Define KSStatement class
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import JavaScriptKit
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

        open func encode() -> String {
                NSLog("[Error] Must be override")
                return ""
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

        public override func encode() -> String {
                var result: String = ""
                for stmt in mStatements {
                        result += stmt.encode() + "\n"
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

        public override func encode() -> String {
                let pname:      String = processIdVariableName(processId: mProcessId)
                let newProcess: String = KSLibrary.BuiltinName.newProcess.rawValue
                let argstr:     String = stringArrayValue(strings: mArguments)

                let defin:  String = KSLibrary.BuiltinName.defaultInputFileHandle.rawValue
                let defout: String = KSLibrary.BuiltinName.defaultOutputFileHandle.rawValue
                let deferr: String = KSLibrary.BuiltinName.defaultErrorFileHandle.rawValue

                let line0 = "let \(pname) = \(newProcess)() ;"
                let line1 = "\(pname).executableURL  = newURL(\"\(mCommandPath)\") ;"
                let line2 = "\(pname).arguments      = \(argstr) ;"
                let line3 = "\(pname).standardInput  = \(defin) ;"
                let line4 = "\(pname).standardOutput = \(defout) ;"
                let line5 = "\(pname).standardError  = \(deferr) ;"
                return [line0, line1, line2, line3, line4, line5].joined(separator: "\n")
        }
}

public class KSRunProcessStatement: KSStatement
{
        private var mProcessId:         Int

        public init(processId pid: Int) {
                mProcessId      = pid
        }

        public override func encode() -> String {
                let pname = processIdVariableName(processId: mProcessId)
                return "\(pname).run();"
        }
}

public class KSWaitProcessStatement: KSStatement
{
        private var mProcessId:         Int

        public init(processId pid: Int) {
                mProcessId      = pid
        }

        public override func encode() -> String {
                let pname = processIdVariableName(processId: mProcessId)
                return "\(pname).wait() ;"
        }
}


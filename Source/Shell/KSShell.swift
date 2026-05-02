/*
 * @file KSShell.swift
 * @description Define KSShell
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class KSShell
{
        private var mStandardInput:     FileHandle
        private var mStandardOutput:    FileHandle
        private var mStandardError:     FileHandle
        private var mPreference:        KSPreference
        private var mEnvVariable:       MIEnvVariables
        private var mDoExit:            Bool
        private var mPrompt:            KSPrompt
        private var mReadline:          KSReadLine?
        private var mEngine:            KSEngine

        public init() {
                mDoExit                 = false
                mStandardInput          = FileHandle.standardInput
                mStandardOutput         = FileHandle.standardOutput
                mStandardError          = FileHandle.standardError
                mPreference             = KSPreference()
                mEnvVariable            = MIEnvVariables(parent: nil)
                mPrompt                 = KSPrompt()
                mEngine                 = KSEngine(environment: mEnvVariable)
                mReadline               = nil
        }

        public var standardInput: FileHandle {
                get      { return mStandardInput }
                set(hdl) { mStandardInput = hdl }
        }

        public var standardOutput: FileHandle {
                get      { return mStandardOutput }
                set(hdl) { mStandardOutput = hdl }
        }

        public var standardError: FileHandle {
                get      { return mStandardError }
                set(hdl) { mStandardError = hdl }
        }

        public var preference: KSPreference { get {
                return mPreference
        }}

        public func run() {
                /* load preference */
                mPreference.load()

                /* initialize terminal */
                let readline = KSReadLine(input:  mStandardInput,
                                          output: mStandardOutput,
                                          error:  mStandardError)
                mStandardInput.setReader(reader: {
                        (_ str: String) in self.receiveResponce(readline: readline, string: str)
                })
                mReadline = readline

                /* setup terminal */
                setupTerminal()

                // print prompt
                write(output: [
                        .string(mPrompt.string)
                ])
        }

        public func wait() {
                while !mDoExit {
                        Thread.sleep(forTimeInterval: 0.1)
                }
        }

        private func setupTerminal() {
                let codes: Array<MIEscapeCode> = [
                        .setColor(mPreference.foregroundColor),
                        .setColor(mPreference.backgroundColor)
                ]
                write(output: codes)
        }

        private func receiveResponce(readline rdline: KSReadLine, string str: String) {
                switch MIEscapeCode.decode(string: str) {
                case .success(let ecodes):
                        let commands = rdline.decodeCodes(edcapeCodes: ecodes)
                        executeCommands(commands: commands)
                case .failure(let err):
                        let msg = MIError.errorToString(error: err)
                        write(error: [
                                .string("[Error] \(msg) at \(#file)\n")
                        ])
                }
        }

        private func executeCommands(commands cmds: Array<KSReadLine.Command>) {
                for cmd in cmds {
                        switch cmd {
                        case .execute(let cmd):
                                if !cmd.isEmpty {
                                        executeCommand(commandLine: cmd)
                                }

                                /* print newline and prompt */
                                let newline: MIEscapeCode = .key(.lineFeed)
                                mStandardOutput.write(string: newline.encode())
                                let prompt: MIEscapeCode = .string(mPrompt.string)
                                mStandardOutput.write(string: prompt.encode())
                        case .showHistory(let flag):
                                NSLog("KSShell: showHistory(\(flag))")
                        case .updateCursorPosition(let row, let col):
                                NSLog("\(#file) Update cursor position row=\(row) col=\(col)")
                                mEnvVariable.set(number: NSNumber(value: row), forKey: MIEnvVariables.terminalRowNumber)
                                mEnvVariable.set(number: NSNumber(value: col), forKey: MIEnvVariables.terminalColumnNumber)
                        case .escapeCode(let ecode):
                                /* output to terminal */
                                mStandardOutput.write(string: ecode.encode())
                        }
                }
        }

        private func executeCommand(commandLine str: String) {
                switch KSCommandParser.parse(commandLine: str) {
                case .success(let cmdlines):
                        let transpiler = KSTranspiler()
                        switch transpiler.transpile(commandLine: cmdlines) {
                        case .success(let stmt):
                                executeCommand(statement: stmt)
                        case .failure(let err):
                                let str = MIError.errorToString(error: err)
                                write(error: [.string(str + "\n")])
                        }
                case .failure(let err):
                        let msg = MIError.errorToString(error: err)
                        write(error: [ .string(msg + "\n")])
                }
        }

        private func executeCommand(statement stmt: KSStatementSequence) {
                let prochdl = MIProcessFileHandle(input: mStandardInput, output: mStandardOutput, error: mStandardError)
                switch mEngine.loadContext(processFileHandle: prochdl) {
                case .success(let ctxt):
                        if let err = mEngine.execute(statement: stmt, in: ctxt) {
                                write(errorInfo: err)
                        }
                case .failure(let err):
                        write(errorInfo: err)
                }
        }

        private func write(output ecodes: Array<MIEscapeCode>){
                let str = ecodeToString(escapeCodes: ecodes)
                mStandardOutput.write(string: str)
        }

        private func write(errorInfo einfo: NSError) {
                let emsg = "[Error]] " + MIError.errorToString(error: einfo) + "\n"
                mStandardError.write(string: emsg)
        }

        private func write(error ecodes: Array<MIEscapeCode>){
                let str = ecodeToString(escapeCodes: ecodes)
                mStandardError.write(string: str)
        }

        private func ecodeToString(escapeCodes ecodes: Array<MIEscapeCode>) -> String {
                var result: String = ""
                for ecode in ecodes {
                        result += ecode.encode()
                }
                return result
        }
}


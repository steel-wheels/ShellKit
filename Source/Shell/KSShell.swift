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
        private var mEnvVariable:       MIEnvVariables
        private var mDoExit:            Bool
        private var mPrompt:            KSPrompt
        private var mReadline:          KSReadLine?

        public init() {
                mDoExit                 = false
                mStandardInput          = FileHandle.standardInput
                mStandardOutput         = FileHandle.standardOutput
                mStandardError          = FileHandle.standardError
                mEnvVariable            = MIEnvVariables(parent: nil)
                mPrompt                 = KSPrompt()
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

        public var envVariables: MIEnvVariables { get {
                return mEnvVariable
        }}

        public func run() {
                /* load preference */
                loadPreference()

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

        private func loadPreference() {
                let foregroundColor: MITextColor = .green(true)
                let backgroundColor: MITextColor = .black(false)

                mEnvVariable.set(color: foregroundColor, forKey: .terminalForeground)
                mEnvVariable.set(color: backgroundColor, forKey: .terminalBackground)
        }

        private func setupTerminal() {
                var codes: Array<MIEscapeCode> = []
                if let col = mEnvVariable.color(forKey: .terminalForeground) {
                        codes.append(.setColor(col))
                }
                if let col = mEnvVariable.color(forKey: .terminalBackground) {
                        codes.append(.setColor(col))
                }
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
                                executeCommand(commandLine: cmd)

                                /* print newline and prompt */
                                let newline: MIEscapeCode = .key(.newline)
                                mStandardOutput.write(string: newline.encode())
                                let prompt: MIEscapeCode = .string(mPrompt.string)
                                mStandardOutput.write(string: prompt.encode())
                        case .showHistory(let flag):
                                NSLog("KSShell: showHistory(\(flag))")
                        case .escapeCode(let ecode):
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
                                write(output: [.string(stmt.encode().toString())])
                        case .failure(let err):
                                let str = MIError.errorToString(error: err)
                                write(error: [.string(str + "\n")])
                        }
                case .failure(let err):
                        let msg = MIError.errorToString(error: err)
                        write(error: [ .string(msg + "\n")])
                }
        }

        private func write(output ecodes: Array<MIEscapeCode>){
                let str = ecodeToString(escapeCodes: ecodes)
                mStandardOutput.write(string: str)
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


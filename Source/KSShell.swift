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
                write(output: [escapeCodeToPrintPrompt()])
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
                        let rcodes = rdline.decodeCodes(edcapeCodes: ecodes)
                        if rcodes.count > 0 {
                                write(output: rcodes)
                        }
                        let cmds = rdline.popCommands()
                        if cmds.count > 0 {
                                for cmd in cmds {
                                        executeCommand(commandLine: cmd)
                                }
                        }
                case .failure(let err):
                        let msg = MIError.errorToString(error: err)
                        write(error: [
                                .string("[Error] \(msg) at \(#file)"),
                                .key(.newline)
                        ])
                }
        }

        private func escapeCodeToPrintPrompt() -> MIEscapeCode {
                return .string(mPrompt.string)
        }

        private func executeCommand(commandLine str: String) {
                switch KSCommandLineParser.parse(commandLine: str) {
                case .success(let commands):
                        for cmd in commands {
                                write(output: [
                                        .string(cmd.description),
                                        .key(.newline)
                                ])
                        }
                case .failure(let err):
                        let msg = MIError.errorToString(error: err)
                        write(error: [
                                .string(msg),
                                .key(.newline)
                        ])
                }
                write(error: [
                        escapeCodeToPrintPrompt()
                ])
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


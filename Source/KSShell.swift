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
        private var mInputFileHandle:   FileHandle
        private var mOutputFileHandle:  FileHandle
        private var mErrorFileHandle:   FileHandle
        private var mDoExit:            Bool
        private var mPrompt:            KSPrompt
        private var mReadLine:          KSReadLine

        public init(input infile: FileHandle, output outfile: FileHandle, error errfile: FileHandle) {
                mDoExit                 = false
                mInputFileHandle        = infile
                mOutputFileHandle       = outfile
                mErrorFileHandle        = errfile
                mPrompt                 = KSPrompt()
                mReadLine               = KSReadLine(input: infile, output: outfile, error: errfile)
                mInputFileHandle.setReader(reader: {
                        (_ str: String) in self.receiveResponce(string: str)
                })
        }

        public func main() {
                // print prompt
                write(output: [escapeCodeToPrintPrompt()])

                while !mDoExit {
                        Thread.sleep(forTimeInterval: 0.1)
                }
        }

        private func receiveResponce(string str: String) {
                switch MIEscapeCode.decode(string: str) {
                case .success(let ecodes):
                        let rcodes = mReadLine.decodeCodes(edcapeCodes: ecodes)
                        if rcodes.count > 0 {
                                write(output: rcodes)
                        }
                        let cmds = mReadLine.popCommands()
                        if cmds.count > 0 {
                                for cmd in cmds {
                                        executeCommand(commandLine: cmd)
                                }
                        }
                case .failure(let err):
                        let msg = MIError.errorToString(error: err)
                        write(error: [
                                .insertString("[Error] \(msg) at \(#file)"),
                                .newlineKey
                        ])
                }
        }

        private func escapeCodeToPrintPrompt() -> MIEscapeCode {
                return .insertString(mPrompt.string)
        }

        private func executeCommand(commandLine str: String) {
                switch KSCommandLineParser.parse(commandLine: str) {
                case .success(let commands):
                        for cmd in commands {
                                write(error: [
                                        .insertString(cmd.description),
                                        .newlineKey
                                ])
                        }
                case .failure(let err):
                        let msg = MIError.errorToString(error: err)
                        write(error: [
                                .insertString(msg),
                                .newlineKey
                        ])
                }
                write(error: [
                        escapeCodeToPrintPrompt()
                ])
        }

        public func write(output ecodes: Array<MIEscapeCode>){
                let str = ecodeToString(escapeCodes: ecodes)
                mOutputFileHandle.write(string: str)
        }

        public func write(error ecodes: Array<MIEscapeCode>){
                let str = ecodeToString(escapeCodes: ecodes)
                mErrorFileHandle.write(string: str)
        }

        private func ecodeToString(escapeCodes ecodes: Array<MIEscapeCode>) -> String {
                var result: String = ""
                for ecode in ecodes {
                        result += ecode.encode()
                }
                return result
        }
}


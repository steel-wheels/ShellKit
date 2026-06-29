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

        private enum UpdateTerminalSizeState {
                case initialize
                case getPosition
                case getSize
                case done
        }

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

        public var environment: MIEnvVariables { get {
                return mEnvVariable
        }}

        public var preference: KSPreference { get {
                return mPreference
        }}

        public func run() {
                /* load preference */
                mPreference.load()

                /* initializ environment variables */
                let paths: Array<String> = [
                        "/bin", "/usr/bin"
                ]
                mEnvVariable.set(strings: paths, forKey: MIEnvVariables.paths)
                mEnvVariable.set(url: mPreference.homeDirectory, forKey: MIEnvVariables.home)
                mEnvVariable.set(shellMode: .command)

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
                updateTerminalSize(row: 0, col: 0)
                // wait until the update sequence done
                while(mUpdateTerminalSizeState != .done){
                        Thread.sleep(forTimeInterval: 0.01)
                }

                // print prompt
                write(string: mPrompt.string)
        }

        public func wait() {
                while !mDoExit {
                        Thread.sleep(forTimeInterval: 0.1)
                }
        }

        private func setupTerminal() {
                let codes: Array<MIEscapeCode> = [
                        .setForegroundColor(mPreference.foregroundColor),
                        .setBackgroundColor(mPreference.backgroundColor)
                ]
                write(escapeCodes: codes)
        }

        private var mUpdateTerminalSizeState:   UpdateTerminalSizeState = .initialize
        private var mCursorRowPosition:         Int = 0
        private var mCursorColPosition:         Int = 0

        private func updateTerminalSize(row:Int, col:Int) {
                switch mUpdateTerminalSizeState {
                case .initialize:
                        //NSLog("[0] updateTerminalSize: init")
                        mUpdateTerminalSizeState = .getPosition
                        write(escapeCode: .requestCursorPosition)
                case .getPosition:
                        //NSLog("[1] updateTerminalSize: getPosition row=\(row), col= \(col)")
                        mCursorRowPosition              = row
                        mCursorColPosition              = col
                        mUpdateTerminalSizeState        = .getSize
                        let ecodes: Array<MIEscapeCode> = [
                                .moveCursorTo(9999, 9999),
                                .requestCursorPosition
                        ]
                        write(escapeCodes: ecodes)
                case .getSize:
                        //NSLog("[2] updateTerminalSize: getSize row=\(row), col= \(col)")
                        mEnvVariable.set(number: NSNumber(value: row), forKey: MIEnvVariables.terminalRowNumber)
                        mEnvVariable.set(number: NSNumber(value: col), forKey: MIEnvVariables.terminalColumnNumber)
                        let ecodes: Array<MIEscapeCode> = [
                                .moveCursorTo(mCursorRowPosition, mCursorColPosition)
                        ]
                        write(escapeCodes: ecodes)
                        mUpdateTerminalSizeState = .done
                case .done:
                        break
                }
        }

        private func receiveResponce(readline rdline: KSReadLine, string str: String) {
                switch MIEscapeCode.decode(string: str) {
                case .success(let ecodes):
                        let commands = rdline.decodeCodes(edcapeCodes: ecodes)
                        executeCommands(commands: commands)
                case .failure(let err):
                        let msg = MIError.errorToString(error: err)
                        write(errorCode: .string("[Error] \(msg) at \(#file)\n"))
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
                                let prompt: MIEscapeCode = .string(mPrompt.string)
                                write(escapeCode: prompt)
                        case .showHistory(let flag):
                                NSLog("KSShell: showHistory(\(flag))")
                        case .updateCursorPosition(let row, let col):
                                if mEnvVariable.debugMode() {
                                        NSLog("\(#file) Update cursor position row=\(row) col=\(col)")
                                }
                                switch mUpdateTerminalSizeState {
                                case .initialize:
                                        mCursorRowPosition = row
                                        mCursorColPosition = col
                                case .getPosition, .getSize:
                                        updateTerminalSize(row: row, col: col)
                                case .done:
                                        break
                                }
                        case .escapeCode(let ecode):
                                /* output to terminal */
                                mStandardOutput.write(string: ecode.encode())
                        }
                }
        }

        private func executeCommand(commandLine str: String) {
                switch KSCommandParser.parse(commandLine: str) {
                case .success(let cmdlines):
                        let transpiler = KSTranspiler(envVariable: mEnvVariable)
                        switch transpiler.transpile(commandLine: cmdlines) {
                        case .success(let stmt):
                                executeCommand(statement: stmt)
                        case .failure(let err):
                                let str = MIError.errorToString(error: err)
                                write(errorCode: .string(str + "\n"))
                        }
                case .failure(let err):
                        let msg = MIError.errorToString(error: err)
                        write(errorCode: .string(msg + "\n"))
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

        private func write(string str: String){
                let ecode: MIEscapeCode = .string(str)
                mStandardOutput.write(string: ecode.encode())
        }

        private func write(escapeCode ecode: MIEscapeCode){
                mStandardOutput.write(string: ecode.encode())
        }

        private func write(escapeCodes ecodes: Array<MIEscapeCode>){
                let str = ecodeToString(escapeCodes: ecodes)
                mStandardOutput.write(string: str)
        }

        private func write(errorInfo einfo: NSError) {
                let emsg = "[Error]] " + MIError.errorToString(error: einfo) + "\n"
                mStandardError.write(string: emsg)
        }

        private func write(errorCode ecode: MIEscapeCode){
                mStandardError.write(string: ecode.encode())
        }

        private func ecodeToString(escapeCodes ecodes: Array<MIEscapeCode>) -> String {
                var result: String = ""
                for ecode in ecodes {
                        result += ecode.encode()
                }
                return result
        }
}


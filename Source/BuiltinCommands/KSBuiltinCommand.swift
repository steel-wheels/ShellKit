/*
 * @file KSBuiltinCommand.swift
 * @description Define KSBuiltinCommand class
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import MultiDataKit
import JavaScriptKit
import JavaScriptCore
import Foundation

public enum KSBuiltinCommandName: String {
        case printEnvCommand    = "printenv"
        case runCommand         = "run"
        case whichCommand       = "which"
}

public class KSBuiltinCommand: Thread
{
        public static let AllocateFuncName = "newBuiltinCommand"

        private var mVirtualMachine:    JSVirtualMachine
        private var mExtension:         KSShellExtension

        public var standardInput:  FileHandle           = FileHandle.standardInput
        public var standardOutput: FileHandle           = FileHandle.standardOutput
        public var standardError:  FileHandle           = FileHandle.standardError
        public var environment:    MIEnvVariables       = MIEnvVariables(parent: nil)

        private var mCommandName:       KSBuiltinCommandName    = .whichCommand
        private var mArguments:         Array<String>           = []
        private var mExitCode:          Int                     = -1

        static public func searchBuiltinCommandName(name nm: String) -> KSBuiltinCommandName? {
                return KSBuiltinCommandName(rawValue: nm)
        }

        public init(virtualMachine vm: JSVirtualMachine, extension ext: KSShellExtension) {
                mVirtualMachine = vm
                mExtension      = ext
        }

        public func checkArguments(command cmd: KSBuiltinCommandName, arguments args: Array<String>) -> Result<Array<String>, NSError> {
                switch cmd {
                case .printEnvCommand:
                        return checkPrintArguments(arguments: args)
                case .runCommand:
                        return checkRunArguments(arguments: args)
                case .whichCommand:
                        return checkWhichArguments(arguments: args)
                }
        }

        public func checkPrintArguments(arguments args: Array<String>) -> Result<Array<String>, NSError> {
                return .success(args)
        }

        public func checkRunArguments(arguments args: Array<String>) -> Result<Array<String>, NSError> {
                switch args.count {
                case 0:
                        if let url = selectFile() {
                                return .success([url.path()])
                        } else {
                                let err = MIError.fileError(message: "File name must be given")
                                return .failure(err)
                        }
                case 1:
                        /* path of input file is given */
                        let path = args[0]
                        if FileManager.default.fileExists(atPath: path) {
                                return .success(args)
                        } else {
                                let err = MIError.fileError(message: "File is not exist: \(path)")
                                return .failure(err)
                        }
                default:
                        let err = MIError.fileError(message: "Invalid number of argumengts")
                        return .failure(err)
                }
        }

        private func selectFile() -> URL? {
                guard mExtension.doesSupportFileSelector else { return nil }
                return mExtension.selectFile(title: "Select the script", fileType: .file, extension: "js")
        }

        public func checkWhichArguments(arguments args: Array<String>) -> Result<Array<String>, NSError> {
                guard args.count == 1 else {
                        let err = MIError.fileError(message: "Invalid number of argumengts")
                        return .failure(err)
                }
                let path = args[0]
                if FileManager.default.fileExists(atPath: path) {
                        return .success(args)
                } else {
                        let err = MIError.fileError(message: "File is not exist: \(path)")
                        return .failure(err)
                }
        }

        public var exitCode: Int { get { return mExitCode }}

        public func setup(commandName name: KSBuiltinCommandName){
                mCommandName    = name
                mArguments      = []
        }

        public var arguments: Array<String> {
                get {
                        return mArguments
                }
                set(args) {
                        mArguments = args
                }
        }

        public override func main() {
                switch mCommandName {
                case .printEnvCommand:
                        mExitCode = printEnvCommand()
                case .runCommand:
                        mExitCode = runCommand()
                case .whichCommand:
                        mExitCode = whichCommand()
                }
                self.standardOutput.flush()
                self.standardError.flush()
        }

        private func print(message msg: String) {
                self.standardOutput.write(string: msg)
        }

        private func error(message msg: String) {
                self.standardError.write(string: "[Error] \(msg)\n")
        }

        private func printEnvCommand() -> Int {
                var result = true
                let keys: Array<String>
                let vname: Bool
                if mArguments.count > 0 {
                        keys  = mArguments
                        vname = keys.count > 1
                } else {
                        keys  = environment.allKeys
                        vname = true
                }
                for key in keys {
                        if(!printEnvVar(key: key, withVarName: vname)){
                                result = false
                        }
                }
                return result ? 0 : 1
        }

        private func printEnvVar(key keystr: String, withVarName vname: Bool) -> Bool {
                if let val = environment.value(for: keystr) {
                        if vname {
                                print(message: "\(keystr)=\(val.encode())\n")
                        } else {
                                print(message: "\(val.encode())\n")
                        }
                        return true
                } else {
                        print(message: "[Error] Variable \(keystr) is NOT found\n")
                        return false
                }
        }

        private func runCommand() -> Int {
                guard mArguments.count == 1 else {
                        error(message: "The \"run\" command requires at least one parameter")
                        return -1
                }
                let srcpath = mArguments[0]
                let scrurl  = URL(filePath: srcpath)
                let lib     = KSLibrary()
                let hdl     = MIProcessFileHandle(input: standardInput,
                                                 output: standardOutput,
                                                 error: standardError)
                switch lib.load(virtualMachine: mVirtualMachine, processFileHandle: hdl, environment: self.environment) {
                case .success(let ctxt):
                        if let _ =  lib.load(into: ctxt, sourceFile: scrurl) {
                                standardError.write(string: "Failed to execute: \(srcpath)")
                                return -1
                        } else {
                                return 0 // no error
                        }
                case .failure(_):
                        standardError.write(string: "Failed to load library")
                        return -1
                }
        }

        private func whichCommand() -> Int {
                guard mArguments.count > 0 else {
                        error(message: "The \"which\" command requires at least one parameter")
                        return -1
                }
                let cmdname = mArguments[0]
                switch self.environment.fileNameToExecutableCommandPath(fileName: cmdname) {
                case .success(let url):
                        print(message: url.path + "\n")
                        return 0
                case .failure(let err):
                        error(message: MIError.errorToString(error: err))
                        return -1
                }
        }
}


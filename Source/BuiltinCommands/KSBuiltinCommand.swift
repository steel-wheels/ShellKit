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
        case whichCommand       = "which"
}

public class KSBuiltinCommand: Thread
{
        public static let AllocateFuncName = "newBuiltinCommand"

        public var standardInput:  FileHandle           = FileHandle.standardInput
        public var standardOutput: FileHandle           = FileHandle.standardOutput
        public var standardError:  FileHandle           = FileHandle.standardError
        public var environment:    MIEnvVariables       = MIEnvVariables(parent: nil)

        private var mCommandName:       KSBuiltinCommandName    = .whichCommand
        private var mArguments:         Array<String>           = []
        private var mExitCode:          Int                     = -1

        static func searchBuiltinCommandName(name nm: String) -> KSBuiltinCommandName? {
                return KSBuiltinCommandName(rawValue: nm)
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

@objc public protocol KSBuiltinCommandProtocol: JSExport
{
        var arguments:          JSValue { get set }      // Array<String>
        var standardInput:      JSValue {  get set }
        var standardOutput:     JSValue {  get set }
        var standardError:      JSValue {  get set }
        func run()
        func wait() -> JSValue
}

@objc public class KSBuiltinCommandObject: NSObject, KSBuiltinCommandProtocol
{
        private var mCommand:   KSBuiltinCommand
        private var mContext:   KSContext

        public init(command cmd: KSBuiltinCommand, context ctxt: KSContext){
                mCommand        = cmd
                mContext        = ctxt
        }

        public var arguments: JSValue {
                get {
                        return KSConverter.stringArrayToValue(mCommand.arguments, in: mContext)
                }
                set(val) {
                        switch KSConverter.valueToStringArray(val) {
                        case .success(let strs):
                                mCommand.arguments = strs
                        case .failure(let err):
                                let msg = MIError.errorToString(error: err)
                                NSLog("[Error] \(msg)")
                        }
                }
        }

        public var standardInput: JSValue {
                get {
                        let hdl = KSFileHandle(fileHandle: mCommand.standardInput, context: mContext)
                        return JSValue(object: hdl, in: mContext)
                }
                set(val){
                        if let hdl = val.toObject() as? KSFileHandle {
                                mCommand.standardInput = hdl.core
                        } else {
                                NSLog("[Error] Failed to get standard input")
                        }
                }
        }

        public var standardOutput: JSValue {
                get {
                        let hdl = KSFileHandle(fileHandle: mCommand.standardOutput, context: mContext)
                        return JSValue(object: hdl, in: mContext)
                }
                set(val){
                        if let hdl = val.toObject() as? KSFileHandle {
                                mCommand.standardOutput = hdl.core
                        } else {
                                NSLog("[Error] Failed to get standard input")
                        }
                }
        }

        public var standardError: JSValue {
                get {
                        let hdl = KSFileHandle(fileHandle: mCommand.standardError, context: mContext)
                        return JSValue(object: hdl, in: mContext)
                }
                set(val){
                        if let hdl = val.toObject() as? KSFileHandle {
                                mCommand.standardError = hdl.core
                        } else {
                                NSLog("[Error] Failed to get standard input")
                        }
                }
        }

        public func run() {
                mCommand.start()
        }

        public func wait() -> JSValue {
                let ecode: Int
                switch Thread.wait(thread: mCommand) {
                case .finished:
                        ecode = mCommand.exitCode
                case .cancelled:
                        ecode = -1
                case .executing:
                        NSLog("[Error] Not finished at \(#file)")
                        ecode = -1
                @unknown default:
                        NSLog("[Error] Can not happen at \(#file)")
                        ecode = -1
                }
                return JSValue(int32: Int32(ecode), in: mContext)
        }

        public static func load(context ctxt: KSContext, environment env: MIEnvVariables) {
                let funcname = KSBuiltinCommand.AllocateFuncName

                /* newProcess */
                let newCommandFunc: @convention(block) (_ nameval: JSValue) -> JSValue = {
                        (_ nameval: JSValue) -> JSValue in
                        guard let str = nameval.toString() else {
                                NSLog("[Error] String is required for \(funcname)")
                                return JSValue(nullIn: ctxt)
                        }
                        guard let name = KSBuiltinCommandName(rawValue: str) else {
                                NSLog("[Error] Unknown built in command name: \(str)")
                                return JSValue(nullIn: ctxt)
                        }

                        let cmd = KSBuiltinCommand()
                        cmd.setup(commandName: name)
                        cmd.environment = env

                        let obj = KSBuiltinCommandObject(command: cmd, context: ctxt)
                        return JSValue(object: obj, in: ctxt)
                }

                ctxt.set(name: funcname, function: newCommandFunc)
        }
}


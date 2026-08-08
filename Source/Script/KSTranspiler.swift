/*
 * @file KSTranspiler.swift
 * @description Define KSTranspiler class
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import MultiDataKit
import JavaScriptKit
import JavaScriptCore
import Foundation

public class KSTranspiler
{
        private enum Phase {
                case allocation
                case run
                case wait
        }

        private struct PhaseInfo {
                var phase:      Phase
                var id:         Int

                public init(phase: Phase, id: Int) {
                        self.phase = phase
                        self.id    = id
                }
        }

        private var mExtension: KSShellExtension

        public init(extension ext: KSShellExtension) {
                mExtension = ext
        }

        public func transpile(commandLines cmdlines: Array<KSCommandLine>) -> Result<MIText, NSError> {
                var result = MIParagraph()

                let phases: Array<Phase> =  [.allocation, .run, .wait]
                for phase in phases {
                        var pid = 0
                        for cmdline in cmdlines {
                                let pinfo = PhaseInfo(phase: phase, id: pid)
                                switch transpile(phase: pinfo, commandLine: cmdline) {
                                case .success(let txt):
                                        result.add(text: txt)
                                case .failure(let err):
                                        return .failure(err)
                                }
                                pid += 1
                        }
                }
                return .success(result)
        }

        private func transpile(phase: PhaseInfo, commandLine cmdline: KSCommandLine) -> Result<MIText, NSError> {
                switch cmdline {
                case .exec(let execcmd):
                        return transpile(phase: phase, execCommand: execcmd)
                }
        }

        private func transpile(phase: PhaseInfo, execCommand execcmd: KSExecCommand) -> Result<MIText, NSError> {
                if let bcmd = KSBuiltinCommandName.decodeByName(commandPath: execcmd.commandPath) {
                        /* modift arguments */
                        switch bcmd {
                        case .printEnvCommand:
                                return transpile(phase: phase, printEnvCommand: execcmd.arguments)
                        case .runCommand:
                                return transpile(phase: phase, runCommand: execcmd.arguments)
                        case .whichCommand:
                                return transpile(phase: phase, whichCommand: execcmd.arguments)
                        }
                } else {
                        return transpile(phase: phase, systemCommand: execcmd)
                }
        }

        private func transpile(phase: PhaseInfo, printEnvCommand args: Array<String>) -> Result<MIText, NSError> {
                let param = "[" + args.joined(separator: ",") + "]"
                return transpile(phase: phase, scriptCommand: "printEnv(\(param)) ;")
        }

        private func transpile(phase: PhaseInfo, runCommand args: Array<String>) -> Result<MIText, NSError> {
                if args.count == 0{
                        if let url = selectFile() {
                                return transpile(phase: phase, scriptCommand: "run(newURL(\"\(url.path)\")) ;")
                        } else {
                                let err = MIError.fileError(message: "Failed to select file to run")
                                return .failure(err)
                        }
                } else if args.count == 1 {
                        return transpile(phase: phase, scriptCommand: "run(newURL(\"\(args[0])\")) ;")
                } else {
                        let err = MIError.fileError(message: "Unexpected num of args for run command")
                        return .failure(err)
                }
        }

        private func transpile(phase: PhaseInfo, whichCommand args: Array<String>) -> Result<MIText, NSError> {
                if args.count == 1 {
                        return transpile(phase: phase, scriptCommand: "which(newURL(\"\(args[0])\")) ;")
                } else {
                        let err = MIError.fileError(message: "Unexpected num of args for which command")
                        return .failure(err)
                }
        }

        private func transpile(phase: PhaseInfo, systemCommand execcmd: KSExecCommand) -> Result<MIText, NSError> {
                let pid = phase.id
                let procname = "proc\(pid)"
                switch phase.phase {
                case .allocation:
                        let inf  = inputFileHandleName(processId: pid)
                        let outf = outputFileHandleName(processId: pid)
                        let errf = errorFileHandleName(processId: pid)
                        let scr  = "let \(procname) = allocateProcess(\(inf), \(outf), \(errf)) ;"
                        return .success(MILine(line: scr))
                case .run:
                        let url  = "newURL(\"\(execcmd.commandPath)\")"
                        let args = "[" + execcmd.arguments.joined(separator: ",") + "]"
                        let scr  = "startProcess(\(procname), \(url), \(args)) ;"
                        return .success(MILine(line: scr))
                case .wait:
                        let scr  = "waitProcess(\(procname)) ;"
                        return .success(MILine(line: scr))
                }
        }

        private func transpile(phase: PhaseInfo, scriptCommand scr: String) -> Result<MIText, NSError> {
                let pid = phase.id
                let thdname = "thd\(pid)"
                switch phase.phase {
                case .allocation:
                        let inf  = inputFileHandleName(processId: pid)
                        let outf = outputFileHandleName(processId: pid)
                        let errf = errorFileHandleName(processId: pid)
                        let scr  = "let \(thdname) = allocateThread(\(inf), \(outf), \(errf)) ;"
                        return .success(MILine(line: scr))
                case .run:
                        let scr  = "startThread(\(thdname), \(scr)) ;"
                        return .success(MILine(line: scr))
                case .wait:
                        let scr  = "waitThread(\(thdname)) ;"
                        return .success(MILine(line: scr))
                }
        }

        private func inputFileHandleName(processId pid: Int) -> String {
                return KSLibrary.BuiltinName.standardInputFileHandle.rawValue
        }

        private func outputFileHandleName(processId pid: Int) -> String {
                return KSLibrary.BuiltinName.standardOutputFileHandle.rawValue
        }

        private func errorFileHandleName(processId pid: Int) -> String {
                return KSLibrary.BuiltinName.standardErrorFileHandle.rawValue
        }

        private func selectFile() -> URL? {
                guard mExtension.doesSupportFileSelector else { return nil }
                return mExtension.selectFile(title: "Select the script", fileType: .file, extension: "js")
        }
}

/*
public class KSTranspiler
{
        private var mProcessId:         Int
        private var mBuiltinCommand:    KSBuiltinCommand
        private var mEnvVariable:       MIEnvVariables

        public init(virtualMachine vm: JSVirtualMachine, envVariable env: MIEnvVariables, extension ext: KSShellExtension) {
                mProcessId      = 0
                mBuiltinCommand = KSBuiltinCommand(virtualMachine: vm, extension: ext)
                mEnvVariable    = env
        }

        public func transpile(commandLine cmdlines: Array<KSCommandLine>) -> Result<KSStatementSequence, NSError> {
                let result = KSStatementSequence()
                for cmdline in cmdlines {
                        switch cmdline {
                        case .exec(let execcmd):
                                switch transpile(execCommand: execcmd) {
                                case .success(let stmts):
                                        result.append(contentsOf: stmts)
                                case .failure(let err):
                                        return .failure(err)
                                }
                        }
                }
                return .success(result)
        }

        private func transpile(execCommand execcmd: KSExecCommand) -> Result<Array<KSStatement>, NSError> {
                /* check command type */
                if let bcmd = KSBuiltinCommand.searchBuiltinCommandName(name: execcmd.commandPath) {
                        switch mBuiltinCommand.checkArguments(command: bcmd, arguments: execcmd.arguments) {
                        case .success(let args):
                                var result: Array<KSStatement> = []
                                let pid = uniqProcessId()
                                result.append(KSAllocateBuiltinCommandStatement(processId: pid, command: bcmd, arguments: args))
                                result.append(KSRunProcessStatement(processId: pid))
                                result.append(KSWaitProcessStatement(processId: pid))
                                return .success(result)
                        case .failure(let err):
                                return .failure(err)
                        }
                } else {
                        /* Check command existence */
                        switch mEnvVariable.fileNameToExecutableCommandPath(fileName: execcmd.commandPath) {
                        case .success(let cmdurl):
                                var result: Array<KSStatement> = []
                                let pid       = uniqProcessId()
                                result.append(KSAllocateProcessStatement(processId: pid, commandPath: cmdurl.path, arguments: execcmd.arguments))
                                result.append(KSRunProcessStatement(processId: pid))
                                result.append(KSWaitProcessStatement(processId: pid))
                                return .success(result)
                        case .failure(let err):
                                return .failure(err)
                        }
                }
        }

        private func uniqProcessId() -> Int {
                let pid = mProcessId
                mProcessId += 1
                return pid
        }
}
*/


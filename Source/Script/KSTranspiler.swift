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

        private var mExtension:         KSShellExtension
        private var mEnvironment:       MIEnvVariables

        public init(extension ext: KSShellExtension, environment env: MIEnvVariables) {
                mExtension      = ext
                mEnvironment    = env
        }

        public func transpile(commandLines cmdlines: Array<KSCommandLine>) -> Result<MIText, NSError> {
                let result = MIParagraph()
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
                if let bcmd = KSBuiltinCommand.decodeByName(commandPath: execcmd.commandPath) {
                        /* modift arguments */
                        if let url = bcmd.executableURL {
                                return transpileThread(phase: phase, arguments: execcmd.arguments, file: url)
                        } else {
                                let err = MIError.fileError(message: "No URL for command \(bcmd.commandName)")
                                return .failure(err)
                        }
                } else {
                        return transpileProcess(phase: phase, systemCommand: execcmd)
                }
        }

        private func transpileProcess(phase: PhaseInfo, systemCommand execcmd: KSExecCommand) -> Result<MIText, NSError> {
                let pid = phase.id
                let procname = "proc\(pid)"

                guard let path = FileManager.default.searchExecutableFile(name: execcmd.commandPath, in: mEnvironment) else {
                        return .failure(MIError.fileError(message: "Command not found: \(execcmd.commandPath)"))
                }

                switch phase.phase {
                case .allocation:
                        let inf  = inputFileHandleName(processId: pid)
                        let outf = outputFileHandleName(processId: pid)
                        let errf = errorFileHandleName(processId: pid)
                        let scr  = "let \(procname) = allocateProcess(\(inf), \(outf), \(errf)) ;"
                        return .success(MILine(line: scr))
                case .run:
                        let url  = "newURL(\"\(path.path)\")"
                        let args = "[" + execcmd.arguments.joined(separator: ",") + "]"
                        let scr  = "startProcess(\(procname), \(url), \(args)) ;"
                        return .success(MILine(line: scr))
                case .wait:
                        let scr  = "waitProcess(\(procname)) ;"
                        return .success(MILine(line: scr))
                }
        }

        private func transpileThread(phase: PhaseInfo, arguments args: Array<String>, file url: URL) -> Result<MIText, NSError> {
                let pid = phase.id
                let thdname = "thd\(pid)"

                var arguments: String = "["
                var is1starg = true
                for arg in args {
                        if !is1starg { arguments += ", " }
                        arguments += "\"" + arg + "\""
                        is1starg = false
                }
                arguments += "]"

                let urlstr: String = "newURL(\"" + url.path + "\")"

                switch phase.phase {
                case .allocation:
                        let inf  = inputFileHandleName(processId: pid)
                        let outf = outputFileHandleName(processId: pid)
                        let errf = errorFileHandleName(processId: pid)
                        let scr  = "let \(thdname) = allocateThread(\(inf), \(outf), \(errf)) ;"
                        return .success(MILine(line: scr))
                case .run:
                        let scr  = "startThreadWithFile(\(thdname), \(arguments), \(urlstr)) ;"
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


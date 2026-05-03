/*
 * @file KSTranspiler.swift
 * @description Define KSTranspiler class
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class KSTranspiler
{
        private var mProcessId:         Int
        private var mEnvVariable:       MIEnvVariables

        public init(envVariable env: MIEnvVariables) {
                mProcessId      = 0
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

        private func uniqProcessId() -> Int {
                let pid = mProcessId
                mProcessId += 1
                return pid
        }
}

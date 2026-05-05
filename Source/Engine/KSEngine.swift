/*
 * @file KSEngine.swift
 * @description Define KSEngine class
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import JavaScriptKit
import MultiDataKit
import Foundation
import JavaScriptCore

public class KSEngine
{
        private var mVirtualMachine:    JSVirtualMachine
        private var mEnvVariables:      MIEnvVariables

        public init(environment env: MIEnvVariables) {
                mVirtualMachine = JSVirtualMachine()
                mEnvVariables = env
        }

        public func loadContext(processFileHandle prochdl: MIProcessFileHandle) -> Result<KSContext, NSError> {
                let lib = KSLibrary()
                switch lib.load(virtualMachine: mVirtualMachine, processFileHandle: prochdl, environment: mEnvVariables) {
                case .success(let ctxt):
                        KSBuiltinCommandObject.load(context: ctxt, environment: mEnvVariables)
                        return .success(ctxt)
                case .failure(let err):
                        return .failure(err)
                }
        }

        public func execute(statement stmt: KSStatementSequence, in ctxt: KSContext) -> NSError? {
                let scr = stmt.encode()
                NSLog("SCRIPT: " + scr)
                ctxt.evaluateScript(scr)
                return nil
        }
}

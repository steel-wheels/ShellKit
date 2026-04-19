/*
 * @file KSCommandParser.swift
 * @description Define KSShellParser class
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class KSCommandParser
{
        public static func parse(commandLine cmdline: String) -> Result<Array<KSCommand>, NSError> {
                var commands: Array<Array<String>> = []
                var command:  Array<String> = []

                /* parse command line */
                switch KSCommandToken.parse(commandLine: cmdline) {
                case .success(let tokens):
                        for token in tokens {
                                switch token {
                                case .command(let str):
                                        command.append(str)
                                case .string(let str):
                                        command.append(str)
                                case .pipe:
                                        commands.append(command)
                                        command = []
                                }
                        }
                case .failure(let err):
                        return .failure(err)
                }
                if !command.isEmpty {
                        commands.append(command)
                }

                /* parse commands */
                var result: Array<KSCommand> = []
                for command in commands {
                        switch KSCommandParser.parse(commands: command) {
                        case .success(let cmd):
                                result.append(cmd)
                        case .failure(let err):
                                return .failure(err)
                        }
                }
                return .success(result)
        }

        private static func parse(commands cmds: Array<String>) -> Result<KSCommand, NSError> {
                guard cmds.count > 0 else {
                        let error = MIError.parseError(message: "No string for command", line: 0)
                        return .failure(error)
                }
                let path = cmds[0]
                var args: Array<String> = []
                for i in 1..<cmds.count {
                        args.append(cmds[i])
                }
                return .success(KSCommand(commandPath: path, arguments: args))
        }
}



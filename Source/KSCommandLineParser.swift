/*
 * @file KSShellParser.swift
 * @description Define KSShellParser class
 * @par Copyright
 *   Copyright (C) 2026 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class KSCommandLineParser
{
        public struct Command {
                public var commandPath:         String
                public var arguments:           Array<String>

                public init(commandPath path: String, arguments args: Array<String>) {
                        commandPath     = path
                        arguments       = args
                }

                public var description: String { get {
                        return "command(\(commandPath), [\(arguments)])"
                }}
        }

        public static func parse(commandLine cmdline: String) -> Result<Array<Command>, NSError> {
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
                var result: Array<Command> = []
                for command in commands {
                        switch KSCommandLineParser.parse(commands: command) {
                        case .success(let cmd):
                                result.append(cmd)
                        case .failure(let err):
                                return .failure(err)
                        }
                }
                return .success(result)
        }

        private static func parse(commands cmds: Array<String>) -> Result<Command, NSError> {
                guard cmds.count > 0 else {
                        let error = MIError.parseError(message: "No string for command", line: 0)
                        return .failure(error)
                }
                let path = cmds[0]
                var args: Array<String> = []
                for i in 1..<cmds.count {
                        args.append(cmds[i])
                }
                return .success(Command(commandPath: path, arguments: args))
        }
}



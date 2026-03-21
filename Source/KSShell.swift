/*
 * @file KSShell.swift
 * @description Define KSShell
 * @par Copyright
 *   Copyright (C) 2025 Steel Wheels Project
 */

import MultiDataKit
import Foundation

public class KSShell
{
        private var mFileInterface:     MIFileInterface
        private var mDoExit:            Bool
        private var mPrompt:            KSPrompt
        private var mReadLine:          KSReadLine

        public init(fileInterface fileif: MIFileInterface) {
                mDoExit         = false
                mFileInterface  = fileif
                mPrompt         = KSPrompt()
                mReadLine       = KSReadLine(fileInterface: fileif)
                fileif.setReader(reader: {
                        (_ str: String) in self.receiveResponce(string: str)
                })
        }

        public func main() {
                // print prompt
                write(output: [ .insertString(mPrompt.string)])

                while !mDoExit {
                        Thread.sleep(forTimeInterval: 0.1)
                }
        }

        public func write(output ecodes: Array<MIEscapeCode>){
                let str = ecodeToString(escapeCodes: ecodes)
                mFileInterface.write(string: str)
        }

        private func receiveResponce(string str: String) {
                switch MIEscapeCode.decode(string: str) {
                case .success(let ecodes):
                        let rcodes = mReadLine.decodeCodes(edcapeCodes: ecodes)
                        if rcodes.count > 0 {
                                write(output: rcodes)
                        }
                case .failure(let err):
                        let msg = MIError.errorToString(error: err)
                        mFileInterface.error(string: "[Error] \(msg) at \(#file)")
                }
        }

        private func ecodeToString(escapeCodes ecodes: Array<MIEscapeCode>) -> String {
                var result: String = ""
                for ecode in ecodes {
                        result += ecode.encode()
                }
                return result
        }
}


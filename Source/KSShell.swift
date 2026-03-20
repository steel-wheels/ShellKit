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
        private var mPrompt:            KSPrompt
        private var mReadLine:          KSReadLine

        public init(fileInterface fileif: MIFileInterface) {
                mFileInterface  = fileif
                mPrompt         = KSPrompt()
                mReadLine       = KSReadLine(fileInterface: fileif)
                fileif.setReader(reader: {
                        (_ str: String) in self.receiveResponce(string: str)
                })
        }

        public func main() {
                write(output: [ .insertString(mPrompt.string)])
        }

        public func write(output ecodes: Array<MIEscapeCode>){
                let str = ecodeToString(escapeCodes: ecodes)
                mFileInterface.write(string: str)
        }

        private func receiveResponce(string str: String) {
                switch MIEscapeCode.decode(string: str) {
                case .success(let ecodes):
                        let rescodes = mReadLine.decodeCodes(edcapeCodes: ecodes)
                        if rescodes.count > 0 {
                                write(output: rescodes)
                        }
                case .failure(let err):
                        let msg = MIError.errorToString(error: err)
                        NSLog("[Error] \(msg) at \(#file)")
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


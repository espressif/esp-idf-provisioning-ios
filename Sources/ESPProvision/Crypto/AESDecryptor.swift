//
//  AESDecryptor.swift
//  ESPProvision
//
//  Created by Martin Zarzeczny on 25.02.22.
//

import Foundation
import CommonCrypto

public class AESDecryptor {

    private var cryptor: CCCryptorRef? = nil

    init(with key: Data, and iv: Data) {
        var ccStatus: CCCryptorStatus = 0;

        ccStatus = CCCryptorCreateWithMode(CCOperation(kCCEncrypt), CCMode(kCCModeCTR), CCAlgorithm(kCCAlgorithmAES),
                                           CCPadding(ccNoPadding),
                                           iv.bytes, key.bytes,
                                           kCCKeySizeAES256,
                                           nil, 0, 0,
                                           CCModeOptions(kCCModeOptionCTR_BE),
                                           &cryptor)
    }

    func cryptData(dataIn: Data, operation: CCOperation, mode: CCMode, algorithm: CCAlgorithm, padding: CCPadding, keyLength: size_t, iv: Data, key: Data, error: inout NSError?) -> Data? {
        if key.count != keyLength {
            ESPLog.log("CCCryptorArgument key.length: \(key.count) != keyLength: \(keyLength)");
            if (error != nil) {
                error = NSError(domain: "kArgumentError key length", code: key.count, userInfo: nil)
            }
            return nil;
        }

        var dataOutMoved: size_t = 0
        var dataOutMovedTotal: size_t = 0
        var ccStatus: CCCryptorStatus = 0

        var accumulator : [UInt8] = []

        let dataOutLength: size_t = CCCryptorGetOutputLength(cryptor, dataIn.count, true);
        var dataOut = Array<UInt8>(repeating: 0, count:Int(dataOutLength))

        ccStatus = CCCryptorUpdate(cryptor,
                                   dataIn.bytes, dataIn.count,
                                   &dataOut, dataOutLength,
                                   &dataOutMoved);
        dataOutMovedTotal += dataOutMoved;

        if (ccStatus != kCCSuccess) {
            ESPLog.log("CCCryptorUpdate status: \(ccStatus)")
            if (error != nil) {
                error = NSError(domain: "kUpdateError", code: Int(ccStatus), userInfo: nil)
            }
            CCCryptorRelease(cryptor);
            return nil;
        }

        accumulator += dataOut[0..<Int(dataOutMoved)]
        ccStatus = CCCryptorFinal(cryptor, &dataOut, dataOutLength, &dataOutMoved)

        if (ccStatus != kCCSuccess) {
            ESPLog.log("CCCryptorFinal status: \(ccStatus)");
            if (error != nil) {
                error = NSError(domain: "kFinalError", code: Int(ccStatus), userInfo: nil)
            }
            CCCryptorRelease(cryptor);
            return nil;
        }

        dataOutMovedTotal += dataOutMoved;
        accumulator += dataOut[0..<Int(dataOutMoved)]

        return Data(accumulator)
    }
}

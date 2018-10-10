// Copyright 2018 Espressif Systems (Shanghai) PTE LTD
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  MbedAES.swift
//  EspressifProvision
//

import Foundation

class MbedAES {
    var context = mbedtls_aes_context()
    var iv: Data
    var key: Data

    var streamBlock = Data()
    var nonceCounterOffset = 0

    public init(key: Data, iv: Data) {
        mbedtls_aes_init(&context)
        self.key = key
        self.iv = iv

        mbedtls_aes_setkey_enc(&context, key.bytes, UInt32(key.count * 8))
    }

    deinit {
        mbedtls_aes_free(&context)
    }

    func encrypt(data: Data) -> Data? {
        var returnData: Data?
        let cipherData: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer.allocate(capacity: data.count)

        iv.withUnsafeMutableBytes({ (unsafeIv: UnsafeMutablePointer<UInt8>) in
            streamBlock.withUnsafeMutableBytes({ (unsafeStreamBlock: UnsafeMutablePointer<UInt8>) in
                mbedtls_aes_crypt_ctr(&context,
                                      data.count,
                                      &nonceCounterOffset,
                                      unsafeIv,
                                      unsafeStreamBlock,
                                      data.bytes,
                                      cipherData)
                let cipherResult = NSData(bytesNoCopy: cipherData,
                                          length: data.count) as Data?
                if let cipherResult = cipherResult {
                    returnData = Data(cipherResult)
                }
            })
        })
        return returnData
    }
}

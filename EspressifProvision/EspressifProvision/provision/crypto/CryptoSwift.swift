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
//  EspressifProvision
//

import CryptoSwift
import Foundation

class CryptoAES {
    var iv: Data
    var key: Data

    var streamBlock = Data()
    var nonceCounterOffset = 0
    var aes: AES!
    var decryptor: Updatable!

    public init(key: Data, iv: Data) {
        self.key = key
        self.iv = iv
        aes = try! AES(key: key.bytes, blockMode: CTR(iv: iv.bytes), padding: .noPadding)
        decryptor = try! aes.makeDecryptor()
    }

    func encrypt(data: Data) -> Data? {
        var returnData: Data?
        do {
            let encryptedData = try decryptor.update(withBytes: data.bytes)
            returnData = Data(encryptedData)
        } catch {
            print("Encryption error")
        }
        return returnData
    }
}

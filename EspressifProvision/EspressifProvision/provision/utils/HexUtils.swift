//
//  HexUtils.swift
//  EspressifProvision
//

import Foundation

struct HexUtils {
    static func xor(first: Data, second: Data) -> Data {
        let firstBytes = [UInt8](first)
        let secondBytes = [UInt8](second)

        let maxLength = max(firstBytes.count, secondBytes.count)
        var output = [UInt8].init(repeating: 0, count: maxLength)
        for i in 0 ..< maxLength {
            output[i] = firstBytes[i % firstBytes.count] ^ secondBytes[i % secondBytes.count]
        }

        return Data(output)
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

func base64ToBase64url(base64: String) -> String {
    let base64url = base64
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
    return base64url
}

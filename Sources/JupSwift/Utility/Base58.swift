//
//  Base58.swift
//  JupSwift
//
//  Created by Zhao You on 24/5/25.
//

import Foundation
import BigInt

public enum Base58 {
    private static let alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

    public static func encode(_ bytes: [UInt8]) -> String {
        var intVal = BigUInt(Data(bytes))
        var result = ""

        while intVal > 0 {
            let (quotient, remainder) = intVal.quotientAndRemainder(dividingBy: 58)
            let index = alphabet.index(alphabet.startIndex, offsetBy: Int(remainder))
            result.insert(alphabet[index], at: result.startIndex)
            intVal = quotient
        }

        // Add leading '1's for each leading zero byte
        for byte in bytes {
            if byte == 0 {
                result.insert("1", at: result.startIndex)
            } else {
                break
            }
        }

        return result
    }

    public static func decode(_ string: String) -> [UInt8]? {
        var intVal = BigUInt(0)

        for char in string {
            guard let index = alphabet.firstIndex(of: char) else {
                return nil // Invalid character
            }
            let digit = alphabet.distance(from: alphabet.startIndex, to: index)
            intVal = intVal * 58 + BigUInt(digit)
        }

        var bytes = [UInt8](intVal.serialize())

        // Add leading zero bytes
        for char in string {
            if char == "1" {
                bytes.insert(0, at: 0)
            } else {
                break
            }
        }

        return bytes
    }
    
    public static func encode(_ data: Data) -> String {
        return encode(Array(data))
    }
}

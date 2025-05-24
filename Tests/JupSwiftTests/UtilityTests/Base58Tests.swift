//
//  Base58Tests.swift
//  JupSwift
//
//  Created by Zhao You on 24/5/25.
//

import Testing
@testable import JupSwift

struct Base58Tests {
    @Test func testBase58Encode() {
        var privateKey: [UInt8] = [73,161,3,218,171,241,145,61,212,134,138,58,199,18,220,148,145,176,81,27,241,11,206,144,80,38,18,250,67,227,117,198,45,67,83,235,252,9,46,179,176,126,143,213,128,241,191,126,32,38,167,199,225,219,144,182,206,244,174,32,222,131,4,86]
        var base58Str = Base58.encode(privateKey)
        #expect(base58Str == "2UP5FKy3UM74f4tTxnhX5oThgozobwj2qgVU4o1am5pV2R45GVEwmvo5wcgScFVrRaEdugfEnLUBTey8cATk67v5")

        privateKey = [130,63,199,222,23,140,87,55,3,203,161,198,127,37,129,124,99,229,47,63,78,76,223,183,183,108,46,162,65,37,172,195,77,185,98,207,89,91,114,3,237,25,202,112,225,227,126,186,228,119,73,247,225,47,195,201,8,170,172,100,250,62,115,207]
        base58Str = Base58.encode(privateKey)
        #expect(base58Str == "3c3BgdXZvpvWu6rsdjNpPJkuYyBgcJXCGkxp1ib5pfkVV7bKEKgjxkbUN2FY3nW37FV8T4HSxTZWv9mNa4hDQtvA")

        privateKey = [189,187,91,39,230,194,160,122,120,110,126,188,116,147,186,99,164,10,152,26,74,253,194,128,38,240,68,45,199,186,34,52,111,45,48,244,128,244,203,72,146,233,18,65,211,54,175,90,61,26,19,134,139,143,174,78,45,98,59,17,34,17,157,175]
        base58Str = Base58.encode(privateKey)
        #expect(base58Str == "4o1pdhCoGHRGjoJdDMCZ8gt2QFSUxRpAfmoVjyFJKbZv6XLQqhrN3RveNq43D1RrzqNmz5WVbVLqa6LGmNkauSkW")
    }

    @Test func testBase58Decode() {
        var base58Str = "2UP5FKy3UM74f4tTxnhX5oThgozobwj2qgVU4o1am5pV2R45GVEwmvo5wcgScFVrRaEdugfEnLUBTey8cATk67v5"
        var privateKey = Base58.decode(base58Str)
        #expect(privateKey == [73,161,3,218,171,241,145,61,212,134,138,58,199,18,220,148,145,176,81,27,241,11,206,144,80,38,18,250,67,227,117,198,45,67,83,235,252,9,46,179,176,126,143,213,128,241,191,126,32,38,167,199,225,219,144,182,206,244,174,32,222,131,4,86])

        base58Str = "3c3BgdXZvpvWu6rsdjNpPJkuYyBgcJXCGkxp1ib5pfkVV7bKEKgjxkbUN2FY3nW37FV8T4HSxTZWv9mNa4hDQtvA"
        privateKey = Base58.decode(base58Str)
        #expect(privateKey == [130,63,199,222,23,140,87,55,3,203,161,198,127,37,129,124,99,229,47,63,78,76,223,183,183,108,46,162,65,37,172,195,77,185,98,207,89,91,114,3,237,25,202,112,225,227,126,186,228,119,73,247,225,47,195,201,8,170,172,100,250,62,115,207])

        base58Str = "4o1pdhCoGHRGjoJdDMCZ8gt2QFSUxRpAfmoVjyFJKbZv6XLQqhrN3RveNq43D1RrzqNmz5WVbVLqa6LGmNkauSkW"
        privateKey = Base58.decode(base58Str)
        #expect(privateKey == [189,187,91,39,230,194,160,122,120,110,126,188,116,147,186,99,164,10,152,26,74,253,194,128,38,240,68,45,199,186,34,52,111,45,48,244,128,244,203,72,146,233,18,65,211,54,175,90,61,26,19,134,139,143,174,78,45,98,59,17,34,17,157,175])
    }
}

//
//  SignTransactionTests.swift
//  JupSwift
//
//  Created by Zhao You on 24/5/25.
//

import Testing
@testable import JupSwift

struct SolanaWalletTests {
    
    @Test
    func testSignTransaction() {
        // test sign with privateKey: [UInt8]
        let privateKey: [UInt8] = [
            73,161,3,218,171,241,145,61,212,134,138,58,199,18,220,148,
            145,176,81,27,241,11,206,144,80,38,18,250,67,227,117,198,
            45,67,83,235,252,9,46,179,176,126,143,213,128,241,191,126,
            32,38,167,199,225,219,144,182,206,244,174,32,222,131,4,86
        ]
        
        let base64Transaction = "AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAQAIDC1DU+v8CS6zsH6P1YDxv34gJqfH4duQts70riDegwRWh7Uj+ncbLnnXrncZ0M9fcpfQPh1Y9fJm+wF6ZvdeXAeT62WWp4H7+l5+SX/26TIX4kW9/UIESJwJ9fRHF2a4BeBV0h/1+T5UibrxqsSxFjlJUiOoGJgKrcpTt5U2/pOyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACMlyWPTiSJ8bs9ECkUjg2DC1oTmdr/EIQEjnvY2+n4Wawfg/25zlUN6V1VjNx5VGHM9DdKxojsE6mEACIKeNoGAwZGb+UhFzL/7K26csOb57yM5bvF9xJrLEObOkAAAAC0P/on9df2SnTAmx8pWHneSwmrNt/J3VFLMhqns4zl6Mb6evO+2606PWXzaqvJdDGxu+TC0vbg5HymAgNFL11hBHnVW/IxwG7udMVuzmgVB/2xst6j9I5RArHNola8E48G3fbh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqQctTjnSwEUMprS9ERx1Vf9YfO/78A64br56TcDYlZ4IBwcABQLAXBUABwAJA/ThBQAAAAAABAIAAwwCAAAA8P4UBgAAAAAKBQMAFQsECZPxe2T0hK52/gUGAAIACQQLAQEKGAsAAwIKCQEIChEUDQADAgwODxALExMSBiPlF8uXeuOtKgEAAAAZZAABAOH1BQAAAABm+LQAAAAAADMAAAsDAwAAAQkB1oUQRIHodQ7RqM53G2HBODrXHK0Mt23syD9oedgHJVAFuL2gvqEFOLs1vBY="

        var signedTransactionBase64 = signTransaction(base64Transaction: base64Transaction, privateKey: privateKey)

        #expect(signedTransactionBase64 == "Afoj44vDVRXmWN+2b0XJsCMEUgahMabbSNU+vBnJylWI6A2wncgrljIZOZ9sre83TCsurVREk/X5rJSSiq6hxAuAAQAIDC1DU+v8CS6zsH6P1YDxv34gJqfH4duQts70riDegwRWh7Uj+ncbLnnXrncZ0M9fcpfQPh1Y9fJm+wF6ZvdeXAeT62WWp4H7+l5+SX/26TIX4kW9/UIESJwJ9fRHF2a4BeBV0h/1+T5UibrxqsSxFjlJUiOoGJgKrcpTt5U2/pOyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACMlyWPTiSJ8bs9ECkUjg2DC1oTmdr/EIQEjnvY2+n4Wawfg/25zlUN6V1VjNx5VGHM9DdKxojsE6mEACIKeNoGAwZGb+UhFzL/7K26csOb57yM5bvF9xJrLEObOkAAAAC0P/on9df2SnTAmx8pWHneSwmrNt/J3VFLMhqns4zl6Mb6evO+2606PWXzaqvJdDGxu+TC0vbg5HymAgNFL11hBHnVW/IxwG7udMVuzmgVB/2xst6j9I5RArHNola8E48G3fbh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqQctTjnSwEUMprS9ERx1Vf9YfO/78A64br56TcDYlZ4IBwcABQLAXBUABwAJA/ThBQAAAAAABAIAAwwCAAAA8P4UBgAAAAAKBQMAFQsECZPxe2T0hK52/gUGAAIACQQLAQEKGAsAAwIKCQEIChEUDQADAgwODxALExMSBiPlF8uXeuOtKgEAAAAZZAABAOH1BQAAAABm+LQAAAAAADMAAAsDAwAAAQkB1oUQRIHodQ7RqM53G2HBODrXHK0Mt23syD9oedgHJVAFuL2gvqEFOLs1vBY=")

        // test sign with privateKey: String (Base58)
        let base58Str = "2UP5FKy3UM74f4tTxnhX5oThgozobwj2qgVU4o1am5pV2R45GVEwmvo5wcgScFVrRaEdugfEnLUBTey8cATk67v5"
        signedTransactionBase64 = signTransaction(base64Transaction: base64Transaction, privateKey: base58Str)

        #expect(signedTransactionBase64 == "Afoj44vDVRXmWN+2b0XJsCMEUgahMabbSNU+vBnJylWI6A2wncgrljIZOZ9sre83TCsurVREk/X5rJSSiq6hxAuAAQAIDC1DU+v8CS6zsH6P1YDxv34gJqfH4duQts70riDegwRWh7Uj+ncbLnnXrncZ0M9fcpfQPh1Y9fJm+wF6ZvdeXAeT62WWp4H7+l5+SX/26TIX4kW9/UIESJwJ9fRHF2a4BeBV0h/1+T5UibrxqsSxFjlJUiOoGJgKrcpTt5U2/pOyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACMlyWPTiSJ8bs9ECkUjg2DC1oTmdr/EIQEjnvY2+n4Wawfg/25zlUN6V1VjNx5VGHM9DdKxojsE6mEACIKeNoGAwZGb+UhFzL/7K26csOb57yM5bvF9xJrLEObOkAAAAC0P/on9df2SnTAmx8pWHneSwmrNt/J3VFLMhqns4zl6Mb6evO+2606PWXzaqvJdDGxu+TC0vbg5HymAgNFL11hBHnVW/IxwG7udMVuzmgVB/2xst6j9I5RArHNola8E48G3fbh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqQctTjnSwEUMprS9ERx1Vf9YfO/78A64br56TcDYlZ4IBwcABQLAXBUABwAJA/ThBQAAAAAABAIAAwwCAAAA8P4UBgAAAAAKBQMAFQsECZPxe2T0hK52/gUGAAIACQQLAQEKGAsAAwIKCQEIChEUDQADAgwODxALExMSBiPlF8uXeuOtKgEAAAAZZAABAOH1BQAAAABm+LQAAAAAADMAAAsDAwAAAQkB1oUQRIHodQ7RqM53G2HBODrXHK0Mt23syD9oedgHJVAFuL2gvqEFOLs1vBY=")
    }
}


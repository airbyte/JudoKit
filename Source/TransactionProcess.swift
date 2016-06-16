//
//  TransactionProcess.swift
//  Judo
//
//  Copyright (c) 2016 Alternative Payments Ltd
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

/// Superclass Helper for Collection, Void and Refund
public class TransactionProcess {
    
    /// The receipt ID for a collection, void or refund
    public private (set) var receiptId: String
    /// The amount of the collection, void or refund
    public private (set) var amount: Amount
    /// The payment reference String for a collection, void or refund
    public private (set) var paymentReference: String = ""
    /// Device identification for this transaction to prevent fraud
    public private (set) var deviceSignal: JSONDictionary?
    /// The current Session to access the Judo API
    public var apiSession: Session?
    
    
    /**
     Starting point and a reactive method to create a collection, void or refund
     
     - Parameter receiptId: the receiptId identifying the transaction you wish to collect, void or refund - has to be luhn-valid
     - Parameter amount: The amount to process
     
     - Throws: LuhnValidationError judoId does not match the given length or is not luhn valid
     */
    init(receiptId: String, amount: Amount) throws {
        // Initialize variables
        self.receiptId = receiptId
        self.amount = amount
        
        guard let uuidString = UIDevice.current().identifierForVendor?.uuidString else {
            throw JudoError(.UnknownError)
        }
        let finalString = String((uuidString + String(NSDate())).characters.filter { ![":", "-", "+"].contains(String($0)) }).replacingOccurrences(of: " ", with: "")
        self.paymentReference = finalString.substring(to: finalString.index(finalString.endIndex, offsetBy: -4))
        
        // Luhn check the receipt ID
        if !receiptId.isLuhnValid() {
            throw JudoError(.LuhnValidationError)
        }
    }
    
    
    /**
     apiSession caller - this method sets the session variable and returns itself for further use
     
     - Parameter session: the API session which is used to call the Judo endpoints
     
     - Returns: reactive self
     */
    public func set(session: Session) -> Self {
        self.apiSession = session
        return self
    }
    
    
    /**
     Reactive method to set device signal information of the device, this method is optional and is used for fraud prevention
     
     - Parameter deviceSignal: a Dictionary which contains information about the device
     
     - Returns: reactive self
     */
    public func set(deviceSignal: JSONDictionary) -> Self {
        self.deviceSignal = deviceSignal
        return self
    }
    
    
    /**
     Completion caller - this method will automatically trigger a Session Call to the judo REST API and execute the request based on the information that were set in the previous methods
     
     - Parameter block: a completion block that is called when the request finishes
     
     - Returns: reactive self
     */
    public func execute(withCompletion block: (Response) -> ()) -> Self {
        
        guard let parameters = self.apiSession?.progressionParameters(with: receiptId, amount: amount, paymentReference: paymentReference, deviceSignal: deviceSignal) else { return self }
        
        self.apiSession?.POST(self.path(), parameters: parameters) { (response) -> Void in
            block(response)
        }
        
        return self
    }
    
    
    /**
     Helper method for extensions of this class to be able to access the dynamic path value
     
     - returns: the rest api access path of the current class
     */
    public func path() -> String {
        return (self.dynamicType as! TransactionPath.Type).path
    }
    
}

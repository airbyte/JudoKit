//
//  Session.swift
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
import CoreLocation
import PassKit

/// The valid lengths of any judo Id
internal let kJudoIDLenght = (6...10)

/// Typealias for any Key value storage type objects
public typealias JSONDictionary = [String : AnyObject]

/// The Session struct is a wrapper for the REST API calls
public struct Session {
    
    /// The endpoint for REST API calls to the judo API
    private (set) var endpoint = "https://gw1.judopay.com/"
    
    
    /// identifying whether developers are using their own UI or the Judo Out of the box UI
    public var uiClientMode = false
    
    
    /// Set the app to sandboxed mode
    public var sandboxed: Bool = false {
        didSet {
            if sandboxed {
                endpoint = "https://gw1.judopay-sandbox.com/"
            } else {
                endpoint = "https://gw1.judopay.com/"
            }
        }
    }
    
    
    /// Token and secret are saved in the authorizationHeader for authentication of REST API calls
    var authorizationHeader: String?
    
    
    /**
    POST Helper Method for accessing the judo REST API
    
    - Parameter path:       the path
    - Parameter parameters: information that is set in the HTTP Body
    - Parameter completion: completion callblack block with the results
    */
    public func POST(_ path: String, parameters: JSONDictionary, completion: (Response) -> ()) {
        
        // Create request
        var request = self.createRequest(with: endpoint + path)
        
        // Rquest method
        request.httpMethod = "POST"
        
        // Safely create request body for the request
        let requestBody: Data?
        
        do {
            requestBody = try JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions.prettyPrinted)
        } catch {
            print("body serialization failed")
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(nil, JudoError(.SerializationError))
            })
            return // BAIL
        }
        
        request.httpBody = requestBody
        
        // Create a data task
        let task = self.task(with: request, completion: completion)
        
        // Initiate the request
        task.resume()
    }
    
    
    /**
    GET Helper Method for accessing the judo REST API
    
    - Parameter path:       the path
    - Parameter parameters: information that is set in the HTTP Body
    - Parameter completion: completion callblack block with the results
    */
    func GET(_ path: String, parameters: JSONDictionary?, completion: (Response) -> ()) {
        
        // Create request
        var request = self.createRequest(with: endpoint + path)
        
        request.httpMethod = "GET"
        
        if let params = parameters {
            let requestBody: Data?
            do {
                requestBody = try JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions.prettyPrinted)
            } catch  {
                print("body serialization failed")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion(nil, JudoError(.SerializationError))
                })
                return
            }
            request.httpBody = requestBody
        }
        
        let task = self.task(with: request, completion: completion)
        
        // Initiate the request
        task.resume()
    }
    
    
    /**
    PUT Helper Method for accessing the judo REST API - PUT should only be accessed for 3DS transactions to fulfill the transaction
    
    - Parameter path:       the path
    - Parameter parameters: information that is set in the HTTP Body
    - Parameter completion: completion callblack block with the results
    */
    func PUT(_ path: String, parameters: JSONDictionary, completion: (Response) -> ()) {
        // Create request
        var request = self.createRequest(with: endpoint + path)
        
        // Request method
        request.httpMethod = "PUT"
        
        // Safely create request body for the request
        let requestBody: Data?
        
        do {
            requestBody = try JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions.prettyPrinted)
        } catch {
            print("body serialization failed")
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(nil, JudoError(.SerializationError))
            })
            return // BAIL
        }
        
        request.httpBody = requestBody
        
        // Create a data task
        let task = self.task(with: request, completion: completion)
        
        // Initiate the request
        task.resume()
    }
    
    // MARK: Helpers
    
    
    /**
    Helper Method to create a JSON HTTP request with authentication
    
    - Parameter url: the url for the request
    
    - Returns: a JSON HTTP request with authorization set
    */
    public func createRequest(with url: String) -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        // json configuration header
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("5.0.0", forHTTPHeaderField: "API-Version")
        
        // Adds the version and lang of the SDK to the header
        request.addValue("iOS-Version/\(JudoKitVersion) lang/(Swift)", forHTTPHeaderField: "User-Agent")
        
        request.addValue("iOSSwift-\(JudoKitVersion)", forHTTPHeaderField: "Sdk-Version")
        
        var uiClientModeString = "Judo-SDK"
        
        if uiClientMode {
            uiClientModeString = "Custom-UI"
        }
        
        request.addValue(uiClientModeString, forHTTPHeaderField: "UI-Client-Mode")
        
        // Check if token and secret have been set
        guard let authHeader = self.authorizationHeader else {
            print("token and secret not set")
            assertionFailure("token and secret not set")
            return request
        }
        
        // Set auth header
        request.addValue(authHeader, forHTTPHeaderField: "Authorization")
        return request
    }
    
    
    /**
    Helper Method to create a JSON HTTP request with authentication
    
    - Parameter request: the request that is accessed
    - Parameter completion: a block that gets called when the call finishes, it carries two objects that indicate whether the call was a success or a failure
    
    - Returns: a NSURLSessionDataTask that can be used to manipulate the call
    */
    public func task(with request: URLRequest, completion: (Response) -> ()) -> URLSessionDataTask {
        return URLSession.shared().dataTask(with: request, completionHandler: { (data, resp, err) -> Void in
            
            // Error handling
            if data == nil, let error = err {
                DispatchQueue.main.async(execute: {
                    completion(Response(error: JudoError.from(NSError: error)))
                })
                return // BAIL
            }
            
            // Unwrap response data
            guard let upData = data else {
                DispatchQueue.main.async(execute: { 
                    completion(Response(error: JudoError(.RequestError)))
                })
                return // BAIL
            }
            
            // Serialize JSON Dictionary
            let json: JSONDictionary?
            do {
                json = try JSONSerialization.jsonObject(with: upData, options: JSONSerialization.ReadingOptions.allowFragments) as? JSONDictionary
            } catch {
                print(error)
                DispatchQueue.main.async(execute: { 
                    completion(Response(error: JudoError(.SerializationError)))
                })
                return // BAIL
            }
            
            // Unwrap optional dictionary
            guard let upJSON = json else {
                DispatchQueue.main.async(execute: {
                    completion(Response(error: JudoError(.SerializationError)))
                })
                return
            }
            
            // If an error occur
            if let errorCode = upJSON["code"] as? Int, let judoErrorCode = JudoErrorCode(rawValue: errorCode) {
                DispatchQueue.main.async(execute: {
                    completion(Response(error: JudoError(judoErrorCode, dict: upJSON)))
                })
                return // BAIL
            }
            
            // Check if 3DS was requested
            if upJSON["acsUrl"] != nil && upJSON["paReq"] != nil {
                DispatchQueue.main.async(execute: {
                    completion(Response(error: JudoError(.ThreeDSAuthRequest, payload: upJSON)))
                })
                return // BAIL
            }
            
            // Create pagination object
            var paginationResponse: Pagination?
            
            if let offset = upJSON["offset"] as? NSNumber, let pageSize = upJSON["pageSize"] as? NSNumber, let sort = upJSON["sort"] as? String {
                paginationResponse = Pagination(pageSize: pageSize.intValue, offset: offset.intValue, sort: Sort(rawValue: sort)!)
            }
            
            var response = Response(paginationResponse)
            
            
            do {
                if let results = upJSON["results"] as? Array<JSONDictionary> {
                    for item in results {
                        let transaction = try TransactionData(item)
                        response.value?.append(element: transaction)
                    }
                } else {
                    let transaction = try TransactionData(upJSON)
                    response.value?.append(element: transaction)
                }
            } catch {
                print(error)
                DispatchQueue.main.async(execute: { 
                    completion(Response(error: JudoError(.ResponseParseError)))
                })
                return // BAIL
            }
            
            DispatchQueue.main.async(execute: {
                completion(response)
            })
            
        })
        
    }
    
    
    /**
    Helper method to create a dictionary of all the parameters necessary for a refund or a collection
    
    - parameter receiptId:        The receipt ID for a refund or a collection
    - parameter amount:           The amount to process
    - parameter paymentReference: the payment reference
    
    - returns: a Dictionary containing all the information to submit for a refund or a collection
    */
    func progressionParameters(receiptId: String, amount: Amount, paymentReference: String, deviceSignal: JSONDictionary?) -> JSONDictionary {
        var dictionary = ["receiptId":receiptId, "amount": amount.amount, "yourPaymentReference": paymentReference]
        if let deviceSignal = deviceSignal {
            dictionary["clientDetails"] = deviceSignal
        }
        return dictionary
    }
    
    
}


// MARK: Pagination

/**
 **Pagination**

 Struct to save state of a paginated response
*/
public struct Pagination {
    var pageSize: Int = 10
    var offset: Int = 0
    var sort: Sort = .Descending
}


/**
 Enum to identify sorting direction
 
 - Descending: Descended Sorting
 - Ascending:  Ascended Sorting
 */
public enum Sort: String {
    /// Descended Sorting
    case Descending = "time-descending"
    /// Ascended Sorting
    case Ascending = "time-ascending"
}


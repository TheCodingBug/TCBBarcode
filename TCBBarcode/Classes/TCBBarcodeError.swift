//
//  TCBBarcodeError.swift
//  TCBBarcode
//
//  Created by Neil Francis Hipona on 4/20/20.
//

import Foundation

public class TCBBarcodeError {
    
    public class func createCustomError(withDomain domain: String = "com.TCBBarcodeError", code: Int = 4776, userInfo: [String: Any]?) -> Error {
        
        return NSError(domain: domain, code: code, userInfo: userInfo)
    }
    
    public class func createCustomError(withDomain domain: String = "com.TCBBarcodeError", code: Int = 4776, errorMessage msg: String) -> Error {
        
        return NSError(domain: domain, code: code, userInfo: ["message": msg])
    }
    
}

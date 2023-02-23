//
//  IAPManagerError.swift
//  InAppPurchaseKit
//
//  Created by Rahul Patra on 31/01/23.
//

import Foundation
import StoreKit

public enum IAPManagerError: Error {
    case custom(String)
    case noProductIDsFound
    case noProductsFound
    case transactionFailed(SKPaymentTransaction, SKPaymentQueue)
    case productRequestFailed
    case didFailWithError(Error)
}

extension IAPManagerError: LocalizedError {
     public var errorDescription: String? {
        switch self {
        case .noProductIDsFound: return "No In-App Purchase product identifiers were found."
        case .noProductsFound: return "No In-App Purchases were found."
        case .productRequestFailed: return "Unable to fetch available In-App Purchase products at the moment."
        case .transactionFailed: return "In-App Purchase process was failed."
        case .didFailWithError(let error):
            return "ERROR! Failed to load purchasable products with error: \(error.localizedDescription)"
        case .custom(let customError):
            return customError
        }
    }
}


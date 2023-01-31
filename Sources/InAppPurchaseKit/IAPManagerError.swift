//
//  IAPManagerError.swift
//  InAppPurchaseKit
//
//  Created by Rahul Patra on 31/01/23.
//

import Foundation

enum IAPManagerError: Error {
    case custom(String)
    case noProductIDsFound
    case noProductsFound
    case paymentWasCancelled
    case productRequestFailed
}

extension IAPManagerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noProductIDsFound: return "No In-App Purchase product identifiers were found."
        case .noProductsFound: return "No In-App Purchases were found."
        case .productRequestFailed: return "Unable to fetch available In-App Purchase products at the moment."
        case .paymentWasCancelled: return "In-App Purchase process was cancelled."
        case .custom(let customError):
            return customError
        }
    }
}

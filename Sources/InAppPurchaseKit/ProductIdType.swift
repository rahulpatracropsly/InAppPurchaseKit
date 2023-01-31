//
//  ProductIdType.swift
//  InAppPurchaseKit
//
//  Created by Rahul Patra on 31/01/23.
//

import Foundation

enum ProductIdType {
    
    case consumable(String)
    case nonConsumable(String)
    case autoRenewal(String)
    case nonAutoRenewal(String)
    
    func getProductId() -> String {
        switch self {
        case .consumable(let key):
            return key
        case .nonConsumable(let key):
            return key
        case .autoRenewal(let key):
            return key
        case .nonAutoRenewal(let key):
            return key
        }
    }
}

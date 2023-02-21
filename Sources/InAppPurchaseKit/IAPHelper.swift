//
//  IAPHelper.swift
//  InAppPurchaseKit
//
//  Created by Rahul Patra on 20/01/23.
//

import Foundation
import StoreKit

open class IAPHelper: NSObject {

    public typealias IAPSuccessFailure = (Result<String?, IAPManagerError>) -> Void
    public typealias IAPShouldAddStorePayment = (SKPaymentQueue, SKPayment, SKProduct) -> Void
    
    private var currentSelctedProductIdType: ProductIdType?
    private var onReceiveProductsHandler: IAPSuccessFailure?
    private var cachedPayment: SKPayment?
    private var shouldAddStorePayment: Bool = false
    private var onReceiveShouldAddStorePayment: IAPShouldAddStorePayment?
    
    var hasCachedPayments: Bool {
        return cachedPayment != nil
    }

    public override init() {
        super.init()
        startObservingPaymentQueue()
    }
    
    private func startObservingPaymentQueue() {
        SKPaymentQueue.default().add(self)
    }

    public func make(paymentFor productIdType: ProductIdType) {
        currentSelctedProductIdType = productIdType
        get(productIds: [productIdType.getProductId()])
    }
    
    public func set(successFailure completion: IAPSuccessFailure?) {
        onReceiveProductsHandler = completion
    }

    public func restorePurchases() {
        if SKPaymentQueue.canMakePayments() {
            SKPaymentQueue.default().restoreCompletedTransactions()
        } else {
            onReceiveProductsHandler?(.failure(.custom("ERROR: restore purchase failed")))
        }
    }
    
    private func get(productIds ids: Set<String>) {
        if SKPaymentQueue.canMakePayments() {
            let request = SKProductsRequest(productIdentifiers: ids)
            request.delegate = self
            request.start()
        } else {
            onReceiveProductsHandler?(.failure(.custom("ERROR: product Not Available")))
        }
    }

    private func buy(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func handleCachedPayments() {
        
        guard let cachedPayment = cachedPayment else {
            // We don't have any cached payments
            return
        }
        
        SKPaymentQueue.default().add(cachedPayment)
        self.cachedPayment = nil
    }
    
    func clearCachedPayments() {
        cachedPayment = nil
    }
    
    public func set(shouldAddStorePayment bool: Bool, shouldAddStorePaymentHandler: IAPShouldAddStorePayment? = nil) {
        self.onReceiveShouldAddStorePayment = shouldAddStorePaymentHandler
        self.shouldAddStorePayment = bool
    }
}

extension IAPHelper: SKProductsRequestDelegate {

    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {

        let products = response.products as [SKProduct]

        if let buyingProduct = products.filter({ $0.productIdentifier == self.currentSelctedProductIdType?.getProductId() ?? "" }).first {
            buy(product: buyingProduct)
        } else {
            onReceiveProductsHandler?(.failure(.noProductsFound))
        }
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        onReceiveProductsHandler?(.failure(.custom(error.localizedDescription)))
    }
    
    func getReceipt() throws -> String? {
        let appStoreReceiptUrl = Bundle.main.appStoreReceiptURL
        do {
            let receiptData = try Data(contentsOf: appStoreReceiptUrl!)
            let receiptString = receiptData.base64EncodedString(options: [])
            return receiptString
        } catch {
           throw error
        }
    }
}

extension IAPHelper: SKPaymentTransactionObserver {

    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                completeTransaction(transaction: transaction)
                break
            case .failed:
                failedTransaction(transaction: transaction)
                break
            case .restored:
                restoreTransaction(transaction: transaction)
                break
            case .deferred:
                deferredTransaction(transaction: transaction)
                break
            case .purchasing:
                purchasingTransaction(transaction: transaction)
                break
            default:
                break
            }
        }
    }

    private func completeTransaction(transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
        do {
            let receiptString = try getReceipt()
            onReceiveProductsHandler?(.success(receiptString))
        } catch {
            onReceiveProductsHandler?(.failure(.custom(error.localizedDescription)))
        }
    }

    private func restoreTransaction(transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
        do {
            let receiptString = try getReceipt()
            onReceiveProductsHandler?(.success(receiptString))
        } catch {
            onReceiveProductsHandler?(.failure(.custom(error.localizedDescription)))
        }
    }

    private func failedTransaction(transaction: SKPaymentTransaction) {

        if let error = transaction.error as NSError? {
            if error.domain == SKErrorDomain {
                // handle all possible errors
                switch (error.code) {
                case SKError.unknown.rawValue:
                    onReceiveProductsHandler?(.failure(.custom("Unknown error")))
                    
                case SKError.clientInvalid.rawValue:
                    onReceiveProductsHandler?(.failure(.custom("client is not allowed to issue the request")))

                case SKError.paymentCancelled.rawValue:
                    onReceiveProductsHandler?(.failure(.paymentWasCancelled))

                case SKError.paymentInvalid.rawValue:
                    onReceiveProductsHandler?(.failure(.custom("purchase identifier was invalid")))

                case SKError.paymentNotAllowed.rawValue:
                    onReceiveProductsHandler?(.failure(.custom("this device is not allowed to make the payment")))

                default:
                    onReceiveProductsHandler?(.failure(.custom("default Unknown error")))
                    break;
                }
            }
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func purchasingTransaction(transaction: SKPaymentTransaction) {
        onReceiveProductsHandler?(.failure(.custom("INFO! User is attempting to purchase product id: \(transaction.payment.productIdentifier)")))
    }
    
    private func deferredTransaction(transaction: SKPaymentTransaction) {
        onReceiveProductsHandler?(.failure(.custom("INFO! Purchase deferred for product id: \(transaction.payment.productIdentifier)")))
    }
}

extension IAPHelper {
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        cachedPayment = payment
        self.onReceiveShouldAddStorePayment?(queue, payment, product)
        return self.shouldAddStorePayment
    }
}

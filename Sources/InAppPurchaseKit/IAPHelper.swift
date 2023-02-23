//
//  IAPHelper.swift
//  InAppPurchaseKit
//
//  Created by Rahul Patra on 20/01/23.
//

import Foundation
import StoreKit

open class IAPHelper: NSObject {

    public typealias IAPSuccessFailure = (Result<(receipt: String?, transaction: SKPaymentTransaction, queue: SKPaymentQueue), IAPManagerError>) -> Void
    public typealias IAPShouldAddStorePayment = (SKPaymentQueue, SKPayment, SKProduct) -> Void
    public typealias IAPRestoreTransactionStatusCompletion = (Result<SKPaymentQueue, Error>) -> Void
    public typealias IAPDidReceiveProductCompletion = ([SKProduct]) -> Void
     
    private var currentSelctedProductIdType: ProductIdType?
    private var onReceiveProductsHandler: IAPSuccessFailure?
    private var cachedPayment: SKPayment?
    private var shouldAddStorePayment: Bool = false
    private var onReceiveShouldAddStorePayment: IAPShouldAddStorePayment?
    private var onReceiveRestoreTransactionStatusCompletion: IAPRestoreTransactionStatusCompletion?
    private var onReceiveProductRequestCompletion: IAPDidReceiveProductCompletion?
    private var mainProducts: [SKProduct] = []

    public var hasCachedPayments: Bool {
        return cachedPayment != nil
    }
    
    public var hasProducts: Bool {
        return mainProducts.count > 0
    }
    
    public override init() {
        super.init()
        startObservingPaymentQueue()
    }
    
    private func startObservingPaymentQueue() {
        SKPaymentQueue.default().add(self)
    }
    
    public func handleCachedPayments() {
        guard let cachedPayment = cachedPayment else {
            // We don't have any cached payments
            return
        }
        SKPaymentQueue.default().add(cachedPayment)
        self.cachedPayment = nil
    }
        
    public func clearCachedPayments() {
        cachedPayment = nil
    }

    public func make(paymentFor productIdType: ProductIdType) {
        currentSelctedProductIdType = productIdType
        if let product = self.mainProducts.filter({ $0.productIdentifier == productIdType.getProductId() }).first {
            buy(product: product)
        } else {
            onReceiveProductsHandler?(.failure(.custom("ERROR! Could not found a product with id: \(productIdType.getProductId())")))
        }
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
    
    /**
        call it before using make payment for function
     */
    public func get(productIds ids: Set<String>) {
        if SKPaymentQueue.canMakePayments() {
            let request = SKProductsRequest(productIdentifiers: ids)
            request.delegate = self
            request.start()
        } else {
            onReceiveProductsHandler?(.failure(.custom("ERROR: product Not Available")))
        }
    }

    public func buy(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    public func set(shouldAddStorePayment bool: Bool, shouldAddStorePaymentHandler: IAPShouldAddStorePayment? = nil) {
        self.onReceiveShouldAddStorePayment = shouldAddStorePaymentHandler
        self.shouldAddStorePayment = bool
    }
    
    public func set(restoreTransactionStatusCompletion: IAPRestoreTransactionStatusCompletion? = nil) {
        self.onReceiveRestoreTransactionStatusCompletion = restoreTransactionStatusCompletion
    }
    
    public func set(didReceiveCompletion: IAPDidReceiveProductCompletion? = nil) {
        self.onReceiveProductRequestCompletion = didReceiveCompletion
    }
    
    public func finish(transactionList: [SKPaymentTransaction], inQueue queue: SKPaymentQueue) {
        for transaction in transactionList {
            queue.finishTransaction(transaction)
        }
    }
}

extension IAPHelper: SKProductsRequestDelegate {

    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products as [SKProduct]
        self.mainProducts = products
        self.onReceiveProductRequestCompletion?(products)
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        onReceiveProductsHandler?(.failure(.didFailWithError(error)))
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
                // Transaction is in queue, user has been charged. Client should complete the transaction.
                completeTransaction(for: transaction, in: queue)
                break
            case .failed:
                // Transaction was cancelled or failed before being added to the server queue.
                failedTransaction(for: transaction, in: queue)
                break
            case .restored:
                // INFO! Restore case is handled in `SKPaymentTransactionObserver` methods
                break
            case .deferred:
                // The transaction is in the queue, but its final status is pending external action.
                deferredTransaction(for: transaction, in: queue)
                break
            case .purchasing:
                // Transaction is being added to the server queue.
                purchasingTransaction(for: transaction, in: queue)
                break
            default:
                break
            }
        }
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        onReceiveRestoreTransactionStatusCompletion?(.failure(error))
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        onReceiveRestoreTransactionStatusCompletion?(.success(queue))
    }

    private func completeTransaction(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        queue.finishTransaction(transaction)
        do {
            let receiptString = try getReceipt()
            onReceiveProductsHandler?(.success((receipt: receiptString, transaction: transaction, queue: queue)))
        } catch {
            onReceiveProductsHandler?(.failure(.custom(error.localizedDescription)))
        }
    }

    private func failedTransaction(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        onReceiveProductsHandler?(.failure(.transactionFailed(transaction, queue)))
    }
    
    private func purchasingTransaction(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        onReceiveProductsHandler?(.failure(.custom("INFO! User is attempting to purchase product id: \(transaction.payment.productIdentifier)")))
    }
    
    private func deferredTransaction(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
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

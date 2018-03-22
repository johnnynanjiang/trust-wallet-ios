// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit
import RealmSwift
import UserNotifications

struct TransactionsViewModel {
    private var numberOfReceivedTransactions: Int = 0
    
    var title: String {
        return NSLocalizedString("transactions.tabbar.item.title", value: "Transactions", comment: "")
    }

    static let titleFormmater: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d yyyy"
        return formatter
    }()

    static let backgroundColor: UIColor = {
        return .white
    }()

    static let headerBackgroundColor: UIColor = {
        return UIColor(hex: "fafafa")
    }()

    static let headerTitleTextColor: UIColor = {
        return UIColor(hex: "555357")
    }()

    static let headerTitleFont: UIFont = {
        return UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
    }()

    static let headerBorderColor: UIColor = {
        return UIColor(hex: "e1e1e1")
    }()

    var isBuyActionAvailable: Bool {
        switch config.server {
        case .main, .kovan, .classic, .callisto, .ropsten, .rinkeby, .poa, .sokol, .custom: return false
        }
    }

    var numberOfSections: Int {
        return storage.transactionSections.count
    }

    private let config: Config

    private let network: TrustNetwork

    private let storage: TransactionsStorage

    private let session: WalletSession

    init(
        network: TrustNetwork,
        storage: TransactionsStorage,
        session: WalletSession,
        config: Config = Config()
    ) {
        self.network = network
        self.storage = storage
        self.session = session
        self.config = config
    }

    func transactionsUpdateObservation(with block: @escaping () -> Void) {
        self.storage.transactionsUpdateHandler = block
    }

    func numberOfItems(for section: Int) -> Int {
        return storage.transactionSections[section].items.count
    }

    func item(for row: Int, section: Int) -> Transaction {
        return storage.transactionSections[section].items[row]
    }

    func titleForHeader(in section: Int) -> String {
        let stringDate = storage.transactionSections[section].title
        guard let date = TransactionsViewModel.convert(from: stringDate) else {
            return stringDate
        }

        if NSCalendar.current.isDateInToday(date) {
            return NSLocalizedString("Today", value: "Today", comment: "")
        }
        if NSCalendar.current.isDateInYesterday(date) {
            return NSLocalizedString("Yesterday", value: "Yesterday", comment: "")
        }
        return stringDate
    }

    func hederView(for section: Int) -> UIView {
        return SectionHeader(
            fillColor: TransactionsViewModel.headerBackgroundColor,
            borderColor: TransactionsViewModel.headerBorderColor,
            title: titleForHeader(in: section),
            textColor: TransactionsViewModel.headerTitleTextColor,
            textFont: TransactionsViewModel.headerTitleFont
        )
    }

    func cellViewModel(for indexPath: IndexPath) -> TransactionCellViewModel {
        return TransactionCellViewModel(transaction: storage.transactionSections[indexPath.section].items[indexPath.row], config: config, chainState: session.chainState, currentWallet: session.account)
    }

    func statBlock() -> Int {
        guard let transaction = storage.completedObjects.first else { return 1 }
        return transaction.blockNumber - 2000
    }

    mutating func fetch() {
        fetchTransactions()
        fetchPending()
    }

    func hasContent() -> Bool {
        return !self.storage.transactions.isEmpty
    }

    func fetchTransactions() {
        self.network.transactions(for: session.account.address, startBlock: 1, page: 0, contract: nil) { result in
            guard let transactions = result.0 else { return }
            self.storage.add(transactions)

            let transactionViewModels = transactions.map({ (trasaction: Transaction) -> TransactionViewModel in
                return TransactionViewModel(
                    transaction: trasaction,
                    config: self.config,
                    chainState: self.session.chainState,
                    currentWallet: self.session.account
                )
            })
            let newNumberOfReceivedTransactions = transactionViewModels.reduce(0) { (total, transactionViewModel: TransactionViewModel) in
                total + (transactionViewModel.direction == TransactionDirection.incoming ? 1 : 0)
            }

            if self.numberOfReceivedTransactions < newNumberOfReceivedTransactions {
                let notification = UNMutableNotificationContent()
                notification.title = "News from Trust"
                notification.subtitle = "New received transactions"
                notification.body = "You have got new received transactions"
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: "test2", content: notification, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error: Error?) in
                    if let e = error {
                        print("Error handling local notification: \(e)")
                        return
                    }
                    print("Local notification handled...")
                })
            }
        }
    }

    func addSentTransaction(_ transaction: SentTransaction) {
        let transaction = SentTransaction.from(from: session.account.address, transaction: transaction)
        storage.add([transaction])
    }

    func fetchPending() {
        /*
        self.storage.transactions.forEach { transaction in
            self.network.update(for: transaction, completion: { result in
                switch result.1 {
                case .deleted:
                    //self.storage.delete([result.0])
                default:
                    //self.storage.update(state: result.1, for: result.0)
                }
            })
        }
        */
    }

    static func convert(from title: String) -> Date? {
        return titleFormmater.date(from: title)
    }
}

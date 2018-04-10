// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import Realm
import RealmSwift

class CoinTickerObject: Object, Decodable {
    @objc dynamic var id: String = ""
    @objc dynamic var symbol: String = ""
    @objc dynamic var price: String = ""
    @objc dynamic var percent_change_24h: String = ""
    @objc dynamic var contract: String = ""
    @objc dynamic var image: String = ""
    @objc dynamic var tickersKey: String = ""
    @objc dynamic var key: String = ""

    convenience init(
        id: String,
        symbol: String,
        price: String,
        percent_change_24h: String,
        contract: String,
        image: String,
        tickersKey: String) {
        self.init()
        self.id = id
        self.symbol = symbol
        self.price = price
        self.percent_change_24h = percent_change_24h
        self.contract = contract
        self.image = image
        self.tickersKey = tickersKey
        self.key = "\(self.id)_\(symbol)_\(contract)_\(tickersKey)"
    }

    required init() {
        super.init()
    }

    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }

    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }

    override static func primaryKey() -> String? {
        return "key"
    }
}

extension CoinTickerObject {
    var imageURL: URL? {
        return URL(string: image)
    }

    func rate() -> CurrencyRate {
        return CurrencyRate(
            currency: symbol,
            rates: [
                Rate(
                    code: symbol,
                    price: Double(price) ?? 0,
                    contract: contract
                ),
                ]
        )
    }
}

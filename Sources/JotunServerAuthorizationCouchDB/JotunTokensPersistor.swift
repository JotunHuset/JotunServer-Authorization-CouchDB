//
//  JotunTokensPersistor.swift
//  JotunServer-Authorization-CouchDB
//
//  Created by Sergey Krasnozhon on 4/27/17.
//  Copyright © 2017 Sergey Krasnozhon. All rights reserved.
//

import Foundation
import CouchDB
import JotunServerAuthorization
import JotunServerCouchDBManagement
import SwiftyJSON

public struct JotunTokensPersistor: JotunTokensPersisting {
    private let designName = "tokensdesign"
    private let storeManager: CouchDbStoreManager
    
    private let tokens = CouchDbStoreManager.View(
        name: "user_tokens", mapFunction: JotunTokensPersistor.tokensViewMapFunction())
    
    public init(connectionProperties: ConnectionProperties) {
        let views = [self.tokens]
        let parameters = CouchDbStoreManager.Parameters(databaseName: "jotun_tokens", designName: self.designName,
                                                        views: views, connectionProperties: connectionProperties)
        self.storeManager = CouchDbStoreManager(parameters: parameters)
    }
    
    // MARK: JotunTokensPersisting
    public func userByToken(_ tokenValue: String, oncomplete: @escaping (JotunUserId?, JotunUserPersistingError?) -> Void) {
        let database = self.storeManager.database()
        let parameters: [Database.QueryParameters] = [.keys([tokenValue as Valuetype])]
        database.queryByView(self.tokens.name, ofDesign: self.designName, usingParameters: parameters) {
            (document, error) in
            let result = QueryResultParser().parseFirstItem(from: document, withError: error)
            switch result {
            case .error(let error): oncomplete(nil, error)
            case .item(let item): oncomplete(JotunUserToken.fromJson(item)?.userId, nil)
            }
        }
    }
    
    public func create(token: JotunUserToken, oncomplete: @escaping (JotunUserPersistingError?) -> Void) {
        let database = self.storeManager.database()
        database.create(token.toJson()) { (id, rev, document, error) in
            let error = QueryResultParser().validateResult(id: id, revision: rev, document: document, error: error)
            oncomplete(error)
        }
    }
    
    public func deleteExpiredTokens(for user: JotunUserId) {

    }
    
    // MARK: Private
    private static func tokensViewMapFunction() -> String {
        let template = "function(doc) { if(doc.%@) { emit(doc.%@, [doc]); } }"
        let result = String(format: template,
                            JotunUserToken.ParametersKeys.value, JotunUserToken.ParametersKeys.value)
        return result
    }
}

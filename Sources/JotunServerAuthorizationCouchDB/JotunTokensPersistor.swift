//
//  JotunTokensPersistor.swift
//  JotunServer
//
//  Created by Sergey on 4/27/17.
//
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
            guard let document = document else {
                oncomplete(nil, JotunUserPersistingError.stogareError)
                return
            }
            
            if let error = error {
                oncomplete(nil, JotunUserPersistingError.generalError(error))
                return
            }
            
            guard let rows = document["rows"].array else {
                oncomplete(nil, JotunUserPersistingError.stogareError)
                return
            }
            
            let values = rows.flatMap({ $0["value"] })
            guard let first = values.first?.1, values.count < 2 else {
                oncomplete(nil, JotunUserPersistingError.extraUsersFound)
                return
            }
            oncomplete(JotunUserToken.fromJson(first)?.userId, nil)
        }
    }
    
    public func create(token: JotunUserToken, oncomplete: @escaping (JotunUserPersistingError?) -> Void) {
        let database = self.storeManager.database()
        database.create(token.toJson()) { (id, rev, document, error) in
            if let _ = id {
                oncomplete(nil)
            } else {
                oncomplete(JotunUserPersistingError.stogareError)
            }
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

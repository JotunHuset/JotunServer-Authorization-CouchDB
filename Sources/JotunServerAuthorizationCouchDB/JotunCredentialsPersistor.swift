//
//  JotunCredentialsPersistor.swift
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


public struct JotunCredentialsPersistor: JutonCredentialsPersisting {
    private let designName = "credentialsdesign"
    private let storeManager: CouchDbStoreManager
    
    private let credentials = CouchDbStoreManager.View(
        name: "user_credentials", mapFunction: JotunCredentialsPersistor.credentialsViewMapFunction())
    
    public init(connectionProperties: ConnectionProperties) {
        let views = [self.credentials]
        let parameters = CouchDbStoreManager.Parameters(databaseName: "jotun_credentials", designName: self.designName,
                                                        views: views, connectionProperties: connectionProperties)
        self.storeManager = CouchDbStoreManager(parameters: parameters)
    }
    
    private func isUserExist(_ userId: JotunUserId, oncomplete: @escaping (Bool) -> Void) {
        self.userCredentials(forUser: userId) { (credentials, _) in
            oncomplete(credentials != nil)
        }
    }
    
    // MARK: JutonCredentialsPersisting
    public func userCredentials(forUser userId: JotunUserId, oncomplete: @escaping (JotunUserCredentials?, JotunUserPersistingError?) -> Void) {
        let database = self.storeManager.database()
        let parameters: [Database.QueryParameters] = [.keys([userId.value as Valuetype])]
        database.queryByView(self.credentials.name, ofDesign: self.designName, usingParameters: parameters) {
            (document, error) in
            let result = QueryResultParser().parseFirstItem(from: document, withError: error)
            switch result {
            case .error(let error): oncomplete(nil, error)
            case .item(let item): oncomplete(JotunUserCredentials.fromJson(item), nil)
            }
        }
    }
    
    public func create(credentials: JotunUserCredentials, oncomplete: @escaping (JotunUserPersistingError?) -> Void) {
        self.isUserExist(credentials.userId) { (userExist) in
            if userExist {
                oncomplete(JotunUserPersistingError.cantDuplicateUser)
                return
            }
            let database = self.storeManager.database()
            database.create(credentials.toJson()) { (id, rev, document, error) in
                let error = QueryResultParser().validateResult(id: id, revision: rev, document: document, error: error)
                oncomplete(error)
            }
        }
    }
    
    // MARK:
    private static func credentialsViewMapFunction() -> String {
        let template = "function(doc) { if(doc.%@.%@) { emit(doc.%@.%@, [doc]); } }"
        let result = String(format: template,
                            JotunUserCredentials.ParametersKeys.userId, JotunUserId.ParametersKeys.value,
                            JotunUserCredentials.ParametersKeys.userId, JotunUserId.ParametersKeys.value)
        return result
    }
}

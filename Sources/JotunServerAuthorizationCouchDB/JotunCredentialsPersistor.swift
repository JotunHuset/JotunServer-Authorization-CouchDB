//
//  JotunCredentialsPersistor.swift
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
            oncomplete(JotunUserCredentials.fromJson(first), nil)
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
                if let error = error {
                    oncomplete(JotunUserPersistingError.generalError(error))
                    return
                }

                if let _ = id {
                    oncomplete(nil)
                } else {
                    oncomplete(JotunUserPersistingError.stogareError)
                }
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

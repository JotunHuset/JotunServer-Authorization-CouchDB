//
//  JotunUsersPersistor.swift
//  JotunServer
//
//  Created by Sergey on 4/21/17.
//
//

import Foundation
import CouchDB
import SwiftyJSON
import JotunServerAuthorization
import MiniPromiseKit

public struct JotunUsersPersistor: JotunUserPersisting {
    private let tokensPersistor: JotunTokensPersistor
    private let credentialsPersistor: JotunCredentialsPersistor
    private let queue = DispatchQueue(label: "JotunUsersPersistor")
    
    public init(connectionProperties: ConnectionProperties) {
        self.tokensPersistor = JotunTokensPersistor(connectionProperties: connectionProperties)
        self.credentialsPersistor = JotunCredentialsPersistor(connectionProperties: connectionProperties)
    }
    
    // MARK: JotunUserPersisting
    public func userCredentials(forTokenValue token: String, oncomplete: @escaping (JotunUserCredentials?, JotunUserPersistingError?) -> Void) {
        let initialPromise = {
            return Promise<JotunUserId?> { (fulfill, reject) in
                self.userByToken(token, oncomplete: { (userId, _) in
                    fulfill(userId)
                })
            }
        }
        
        firstly {
            return initialPromise()
            }
            .then(on: self.queue){ (userId) -> JotunUserId in
                guard let userId = userId else { throw JotunUserPersistingError.invalidUserForToken }
                return userId
            }
            .then(on: self.queue) { (userID) in
                self.userCredentials(forUser: userID, oncomplete: { (credentials, error) in
                    oncomplete(credentials, error)
                })
            }
            .catch(on: self.queue) { (error) in
                let resultError = (error as? JotunUserPersistingError) ?? JotunUserPersistingError.generalError(error)
                oncomplete(nil, resultError)
        }
        
    }
    
    // MARK: JutonCredentialsPersisting
    public func create(credentials: JotunUserCredentials, oncomplete: @escaping (JotunUserPersistingError?) -> Void) {
        self.credentialsPersistor.create(credentials: credentials, oncomplete: oncomplete)
    }
    
    public func userCredentials(forUser userId: JotunUserId, oncomplete: @escaping (JotunUserCredentials?, JotunUserPersistingError?) -> Void) {
        self.credentialsPersistor.userCredentials(forUser: userId, oncomplete: oncomplete)
    }
    
    
    // MARK: JotunTokensPersisting
    public func create(token: JotunUserToken, oncomplete: @escaping (JotunUserPersistingError?) -> Void) {
        self.tokensPersistor.create(token: token, oncomplete: oncomplete)
    }
    
    public func userByToken(_ tokenValue: String, oncomplete: @escaping (JotunUserId?, JotunUserPersistingError?) -> Void) {
        self.tokensPersistor.userByToken(tokenValue, oncomplete: oncomplete)
    }
    
    public func deleteExpiredTokens(for user: JotunUserId) {
        self.tokensPersistor.deleteExpiredTokens(for: user)
    }
}

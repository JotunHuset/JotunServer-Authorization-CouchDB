//
//  QueryResultParser.swift
//  JotunServer-Authorization-CouchDB
//
//  Created by Sergey Krasnozhon on 4/30/17.
//
//

import Foundation
import JotunServerAuthorization
import SwiftyJSON

struct QueryResultParser {
    enum Result {
        case item(JSON)
        case error(JotunUserPersistingError)
    }
    
    func parseFirstItem(
        from document: JSON?, withError error: NSError?) -> QueryResultParser.Result {
        guard let document = document else {
            return QueryResultParser.Result.error(JotunUserPersistingError.stogareError)
        }
        
        if let error = error {
            return QueryResultParser.Result.error(JotunUserPersistingError.generalError(error))
        }
        
        guard let rows = document["rows"].array else {
            return QueryResultParser.Result.error(JotunUserPersistingError.stogareError)
        }
        
        let values = rows.flatMap({ $0["value"] })
        guard let first = values.first?.1, values.count < 2 else {
            return QueryResultParser.Result.error(JotunUserPersistingError.extraRecordFound)
        }
        return QueryResultParser.Result.item(first)
    }
    
    func validateResult(id: String?, revision: String?, document: JSON?, error: NSError?) -> JotunUserPersistingError? {
        if let error = error {
            return JotunUserPersistingError.generalError(error)
        }
        
        guard id != nil, revision != nil, document != nil else {
            return JotunUserPersistingError.stogareError
        }
        return nil
    }
}

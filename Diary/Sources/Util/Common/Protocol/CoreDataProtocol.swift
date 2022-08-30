//
//  CoreDataProtocol.swift
//  Diary
//
//  Created by seohyeon park on 2022/08/29.
//

import UIKit
import CoreData

enum CRUDType {
    case create
    case read
    case update
    case delete
    case none
}

protocol CoreDataProtocol {
    var context: NSManagedObjectContext? { get set }
    var type: CRUDType { get set }
    var content: NSManagedObject? { get set }
    
    func createContext()
    func readContext() -> [NSManagedObject]
    func updateContext()
}

extension CoreDataProtocol {
    func deleteContext(data: NSManagedObject) {
        guard let context = context else { return }
        
        context.delete(data)
    }
    
    func saveContext() throws {
        guard let context = context else {
            throw CoreDataError.noContext
        }

        guard (try? context.save()) != nil else {
            throw CoreDataError.failedToSave
        }
    }
    
    func perform() {
        switch type {
        case .create:
            return createContext()
        case .update:
            return updateContext()
        case .delete:
            return deleteContext(data: content!)
        case .none, .read:
            return
        }
    }
}

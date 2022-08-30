//
//  DiaryCoreDataManager.swift
//  Diary
//
//  Created by seohyeon park on 2022/08/29.
//

import UIKit
import CoreData

class DiaryCoreDataManager: CoreDataProtocol {
    var content: NSManagedObject?
    var context: NSManagedObjectContext?
    var type = CRUDType.none
    var data = DiaryContents()
    
    init(context: NSManagedObjectContext? =
    (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext) {
        self.context = context
    }
    
    func createContext() {
        guard let context = context else {
            return
        }
        
        content = DiaryContents(context: context)
        updateContext()
        
        guard (try? saveContext()) != nil else { return }
    }
    
    func readContext() -> [NSManagedObject] {
        guard let context = context,
              let diaryContents = try? context.fetch(DiaryContents.fetchRequest()) else {
                  return []
        }
        
        return diaryContents
    }
    
    func updateContext() {
        guard let diaryContent = content as? DiaryContents else {
            return
        }
        
        diaryContent.title = data.title
        diaryContent.body = data.body
        diaryContent.createdAt = data.createdAt
        diaryContent.id = data.id
        
        guard (try? saveContext()) != nil else { return }
    }
}

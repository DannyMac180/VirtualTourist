//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Daniel McAteer on 9/11/17.
//  Copyright © 2017 Daniel McAteer. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    
    convenience init(index:Int, imageUrl: String, imageData: NSData?, context: NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            
            self.init(entity: ent, insertInto: context)
            self.index = Int16(index)
            self.imageUrl = imageUrl
            self.imageData = imageData
            
        } else {
            
            fatalError("Unable To Find Entity Name!")
        }
    }
}

//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Daniel McAteer on 9/11/17.
//  Copyright © 2017 Daniel McAteer. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var imageUrl: String?
    @NSManaged public var index: Int16
    @NSManaged public var pin: Pin?

}

//
//  Location.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/3/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import CoreData

@objc(Location)
class Location: NSManagedObject
{
  @NSManaged var latitude: NSNumber
  @NSManaged var longitude: NSNumber
  @NSManaged var photoAlbum: [PhotoAlbum]?
  
  override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
    super.init(entity: entity, insertIntoManagedObjectContext: context)
  }
  
  init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
    
    // Core Data
    let entity =  NSEntityDescription.entityForName("Location", inManagedObjectContext: context)!
    super.init(entity: entity, insertIntoManagedObjectContext: context)
    
    // Dictionary
    latitude = dictionary[Keys.Latitude] as! Double
    longitude = dictionary[Keys.Longitude] as! Double
  }


}

//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/3/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import CoreData

@objc(Pin)
class Pin: NSManagedObject
{
  @NSManaged var latitude: NSNumber
  @NSManaged var longitude: NSNumber
  @NSManaged var photoAlbum: [Photo]?
  
  override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
    super.init(entity: entity, insertIntoManagedObjectContext: context)
  }
  
  init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
    
    // Core Data
    let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
    super.init(entity: entity, insertIntoManagedObjectContext: context)
    
    // Dictionary
    self.latitude = latitude
    self.longitude = longitude
    println("longitude in init \(self.longitude)")
  }


}

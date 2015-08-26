//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/3/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import CoreData

@objc(Photo)
class Photo: NSManagedObject
{
  @NSManaged var photo: String?
  @NSManaged var numberOfPhotosInAlbum: NSNumber
  @NSManaged var location: Pin?
  
  override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
    super.init(entity: entity, insertIntoManagedObjectContext: context)
  }
  
  init(photoURL: String, location: Pin, photoAlbumCount: NSNumber, context: NSManagedObjectContext) {
    
    // Core Data
    let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
    super.init(entity: entity, insertIntoManagedObjectContext: context)
    
    photo = photoURL
    self.location = location
    numberOfPhotosInAlbum = photoAlbumCount
  }
}
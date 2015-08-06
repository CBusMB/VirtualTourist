//
//  PhotoAlbum.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/3/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import CoreData

@objc(PhotoAlbum)
class PhotoAlbum: NSManagedObject
{
  @NSManaged var photo: NSData?
  @NSManaged var numberOfPhotosInAlbum: NSNumber
  @NSManaged var location: Location?
  
  override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
    super.init(entity: entity, insertIntoManagedObjectContext: context)
  }
  
  convenience init(insertIntoMangedObjectContext context: NSManagedObjectContext) {
    let entity = NSEntityDescription.entityForName("PhotoAlbum", inManagedObjectContext: context)!
    self.init(entity: entity, insertIntoManagedObjectContext: context)
  }

}
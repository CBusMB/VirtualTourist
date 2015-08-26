//
//  ImageManager.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/14/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import Foundation
import UIKit

class ImageManager: NSObject, NSCoding
{
  let URLStartIndex = -16
  var image: NSData
  
  init(image: NSData) {
    self.image = image
  }
  
  required init(coder unarchiver: NSCoder) {
    image = unarchiver.decodeObjectForKey(Keys.ImageData) as! NSData
    super.init()
  }
  
  func encodeWithCoder(archiver: NSCoder) {
    archiver.encodeObject(image, forKey: Keys.ImageData)
  }
  
  class func savePhotoAlbum(album: [NSData], withPathComponent pathComponent: [String]) {
    let manager = NSFileManager.defaultManager()
    let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
    for i in 0..<album.count {
      let path = pathComponent[i]
      let startIndex = advance(path.endIndex, Constants.StartIndex)
      let truncatedPathComponent = path[Range(start: startIndex, end: path.endIndex)]
      let filePath = url.URLByAppendingPathComponent(truncatedPathComponent).path!
      println("saved image data \(i), to path \(filePath)")
      NSKeyedArchiver.archiveRootObject(album[i], toFile: filePath)
    }
  }
  
  class func deletePhotosAtPathComponents(components: [Photo]) {
    let manager = NSFileManager.defaultManager()
    let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
    for i in 0..<components.count {
      if let path = components[i].photo {
        let startIndex = advance(path.endIndex, Constants.StartIndex)
        let truncatedPathComponent = path[Range(start: startIndex, end: path.endIndex)]
        let filePath = url.URLByAppendingPathComponent(truncatedPathComponent).path!
        let error = NSErrorPointer()
        manager.removeItemAtPath(filePath, error: error)
      }
    }
  }
  
  class func getPhotoForURL(url: String) -> UIImage {
    let manager = NSFileManager.defaultManager()
    let imageURL = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
    let startIndex = advance(url.endIndex, Constants.StartIndex)
    let truncatedPathComponent = url[Range(start: startIndex, end: url.endIndex)]
    let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    let pathArray = [dirPath, truncatedPathComponent]
    let fileURL = NSURL.fileURLWithPathComponents(pathArray)
    let path = imageURL.URLByAppendingPathComponent(truncatedPathComponent)
    println("\(path)")
    var image = UIImage()
    if let imageData = NSData(contentsOfURL: fileURL!) {
      let exists = manager.fileExistsAtPath("\(fileURL)")
      println("\(exists)")
      image = UIImage(data: imageData)!
    }
    return image
  }
}

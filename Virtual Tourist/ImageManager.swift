//
//  ImageManager.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/14/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import UIKit

class ImageManager
{
  
  class func savePhotoAlbum(album: [NSData], withFileName fileName: [String]) {
    let manager = NSFileManager.defaultManager()
    let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
    for i in 0..<album.count {
      let path = fileName[i]
      let startIndex = advance(path.endIndex, Constants.StartIndex)
      let truncatedPathComponent = path[Range(start: startIndex, end: path.endIndex)]
      let filePath = url.URLByAppendingPathComponent(truncatedPathComponent).path!
      println("saved image data \(i), to path \(filePath)")
      album[i].writeToFile(filePath, atomically: true)
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
    let path = imageURL(url)
    var image = UIImage()
    if let imageData = NSData(contentsOfURL: path) {
      image = UIImage(data: imageData)!
    }
    return image
  }
  
  private class func imageURL(url: String) -> NSURL {
    let startIndex = advance(url.endIndex, Constants.StartIndex)
    let truncatedPathComponent = url[Range(start: startIndex, end: url.endIndex)]
    let directoryPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    let pathArray = [directoryPath, truncatedPathComponent]
    let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
    return fileURL
  }
}

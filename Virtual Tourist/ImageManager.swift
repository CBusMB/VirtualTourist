//
//  ImageManager.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/14/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import UIKit
import CoreData

protocol ImageManagerDelegate: class
{
  func imageManagerDidAddImageToCache(flag: Bool, atIndex index: Int)
  func imageManagerDidPersistURLs(flag: Bool)
}

class ImageManager
{
//  var downloadingNewImages: Bool? = false
  var imageDownloadComplete: Bool? = false
//  var downloadingPhotoURLs: Bool? = false
  
  var photoCache = [UIImage]()
  
  var downloadTasks = [NSURLSessionDownloadTask]()
  
  weak var delegate: ImageManagerDelegate?
  
  func savePhotoURLsToCoreData(urls: [String], forLocation location: Pin) {
    println("savePhotoURLsToCoreData")
    for url in urls {
      let photoURL = Photo(photoURL: url, location: location, photoAlbumCount: urls.count, context: sharedContext)
    }
    dispatch_async(dispatch_get_main_queue()) {
      CoreDataStackManager.sharedInstance.saveContext()
      self.delegate?.imageManagerDidPersistURLs(true)
      // self.downloadingPhotoURLs = false
      // println("\(self.downloadingPhotoURLs)")
    }
  }
  
  func downloadPhotoAlbumImageDataFromURLs(urls: [String]) {
    println("downloadPhotoAlbumImageDataFromURLs")
    for url in urls {
      let downloadTask = FlickrClient.downloadImageAtURL(url) { imageData in
        if let dataToWrite = imageData {
          dispatch_async(dispatch_get_main_queue()) {
            self.savePhotoToFileSystemAsData(dataToWrite, withExternalURL: url)
            println("\(self.imageURL(url))")
            self.addDownloadedPhotoToCacheFromURL("\(self.imageURL(url))")
            println("added photo to cache from downloadPhotoAlbumImageDataFromURLs")
          }
        }
      }
      downloadTasks.append(downloadTask)
      println("download tasks: \(downloadTasks.count)")
    }
    imageDownloadComplete = true
  }
  
  func randomURLs(urls: [String]) -> [String] {
    var urlArray = [String]()
    var defaultCount = 21
    if urls.count < 21 {
      defaultCount = urls.count
    }
    for i in 0..<defaultCount {
      let randomIndex = Int(arc4random_uniform(UInt32(urls.count)))
      let randomURL = urls[randomIndex]
      urlArray.append(randomURL)
    }
    return urlArray
  }
  
  func savePhotoToFileSystemAsData(data: NSData, withExternalURL url: String) {
    let manager = NSFileManager.defaultManager()
    let fileSystemURL = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
    let truncatedPathComponent = imageFileName(url)
    let filePath = fileSystemURL.URLByAppendingPathComponent(truncatedPathComponent).path!
    data.writeToFile(filePath, atomically: true)
    println("savePhotoToFileSystemAsData")
  }
  
  func deletePhotosForURLs(urls: [Photo]) {
    let manager = NSFileManager.defaultManager()
    let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
    for i in 0..<urls.count {
      if let path = urls[i].photo {
        let truncatedPathComponent = imageFileName(path)
        let filePath = url.URLByAppendingPathComponent(truncatedPathComponent).path!
        let error = NSErrorPointer()
        manager.removeItemAtPath(filePath, error: error)
      }
    }
  }
  
  ///:param: url - The full local URL path as a String
  func addDownloadedPhotoToCacheFromURL(url: String) {
    println("called addPhotoToCacheFromURL")
    println(url)
    if let imageData = NSData(contentsOfFile: url) {
      let image = UIImage(data: imageData)
      // let imageWithPath = [url : image]
      photoCache.append(image!)
      delegate?.imageManagerDidAddImageToCache(true, atIndex: photoCache.count - 1)
      println("count in add to cache: \(photoCache.count)")
    }
  }
  
  /**
  Takes external urls from CoreData store, grabs the NSData objects from 
  the file system for each url as UIImage,moves each UIImage to an 
  array for easy access by other classes
  
  :param: urls - An array of Photo objects 
  */
  func addPersistedPhotosToCache(urls: [Photo]) {
    println("addPersistedPhotosToCache called")
    for url in urls {
      if let photoURL = url.photo {
        let path = imageURL(photoURL)
        if let image = UIImage(data: NSData(contentsOfFile: "\(path)")!) {
          let imageWithPath = ["\(path)" : image]
          photoCache.append(image)
          delegate?.imageManagerDidAddImageToCache(true, atIndex: photoCache.count - 1)
          println("count in add to cache: \(photoCache.count)")
        }
      }
    }
    // downloadingNewImages = false
  }
  
  private func imageURL(url: String) -> NSURL {
    let truncatedPathComponent = imageFileName(url)
    let directoryPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    let pathArray = [directoryPath, truncatedPathComponent]
    let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
    return fileURL
  }
  
  private func imageFileName(path: String) -> String {
    let startIndex = advance(path.endIndex, Constants.StartIndex)
    return path[Range(start: startIndex, end: path.endIndex)]
  }
  
  //MARK: - Core Data
  var sharedContext: NSManagedObjectContext {
    return CoreDataStackManager.sharedInstance.managedObjectContext!
  }
}

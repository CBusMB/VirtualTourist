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
    print("savePhotoURLsToCoreData")
    for url in urls {
      let _ = Photo(photoURL: url, location: location, photoAlbumCount: urls.count, context: sharedContext)
    }
    dispatch_async(dispatch_get_main_queue()) {
      CoreDataStackManager.sharedInstance.saveContext()
      self.delegate?.imageManagerDidPersistURLs(true)
      // self.downloadingPhotoURLs = false
      // println("\(self.downloadingPhotoURLs)")
    }
  }
  
  func downloadPhotoAlbumImageDataFromURLs(urls: [String]) {
    print("downloadPhotoAlbumImageDataFromURLs")
    for url in urls {
      let downloadTask = FlickrClient.downloadImageAtURL(url) { imageData in
        if let dataToWrite = imageData {
          dispatch_async(dispatch_get_main_queue()) {
            self.savePhotoToFileSystemAsData(dataToWrite, withExternalURL: url)
            print("\(self.imageURL(url))")
//            self.addDownloadedPhotoToCacheFromURL("\(self.imageURL(url))")
//            println("added photo to cache from downloadPhotoAlbumImageDataFromURLs")
          }
        }
      }
      downloadTasks.append(downloadTask)
      print("download tasks: \(downloadTasks.count)")
    }
    // imageDownloadComplete = true
  }
  
  func cancelDownloadTasks() {
    for downloadTask in downloadTasks {
      downloadTask.cancel()
    }
  }
  
  func randomURLs(urls: [String]) -> [String] {
    var urlArray = [String]()
    var defaultCount = 21
    if urls.count < 21 {
      defaultCount = urls.count
    }
    for _ in 0..<defaultCount {
      let randomIndex = Int(arc4random_uniform(UInt32(urls.count)))
      let randomURL = urls[randomIndex]
      urlArray.append(randomURL)
    }
    return urlArray
  }
  
  func savePhotoToFileSystemAsData(data: NSData, withExternalURL url: String) {
    let manager = NSFileManager.defaultManager()
    let fileSystemURL = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
    let truncatedPathComponent = imageFileName(url)
    let filePath = fileSystemURL!.URLByAppendingPathComponent(truncatedPathComponent).path!
    data.writeToFile(filePath, atomically: true)
    print("savePhotoToFileSystemAsData")
    addDownloadedPhotoToCacheFromURL(filePath)
  }
  
  func deletePhotosForURLs(urls: [Photo]) {
    let manager = NSFileManager.defaultManager()
    let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
    for i in 0..<urls.count {
      if let path = urls[i].photo {
        let truncatedPathComponent = imageFileName(path)
        let filePath = url!.URLByAppendingPathComponent(truncatedPathComponent).path!
        do {
          try manager.removeItemAtPath(filePath)
        } catch let error as NSError {
          print(error.localizedDescription)
        }
      }
    }
  }
  
  ///- parameter url: - The full local URL path as a String
  func addDownloadedPhotoToCacheFromURL(url: String) {
    print("called addPhotoToCacheFromURL")
    print(url)
    if let imageData = NSData(contentsOfFile: url) {
      let image = UIImage(data: imageData)
      // let imageWithPath = [url : image]
      photoCache.append(image!)
      delegate?.imageManagerDidAddImageToCache(true, atIndex: photoCache.count - 1)
      print("count in add to cache: \(photoCache.count)")
    }
  }
  
  /**
  Takes external urls from CoreData store, grabs the NSData objects from 
  the file system for each url as UIImage,moves each UIImage to an 
  array for easy access by other classes
  
  - parameter urls: - An array of Photo objects 
  */
  func addPersistedPhotosToCache(urls: [Photo]) {
    print("addPersistedPhotosToCache called")
    resetCacheAndTasks()
    for url in urls {
      if let photoURL = url.photo {
        let path = imageURL(photoURL)
        if let imageData = NSData(contentsOfFile: "\(path)") {
          let image = UIImage(data: imageData)
          // let imageWithPath = ["\(path)" : image]
          photoCache.append(image!)
          delegate?.imageManagerDidAddImageToCache(true, atIndex: photoCache.count - 1)
          print("count in add to cache: \(photoCache.count)")
        }
      }
    }
    // downloadingNewImages = false
  }
  
  func resetCacheAndTasks() {
    photoCache.removeAll(keepCapacity: false)
    downloadTasks.removeAll(keepCapacity: false)
  }
  
  private func imageURL(url: String) -> NSURL {
    let truncatedPathComponent = imageFileName(url)
    let directoryPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
    let pathArray = [directoryPath, truncatedPathComponent]
    let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
    return fileURL
  }
  
  private func imageFileName(path: String) -> String {
    let startIndex = path.endIndex.advancedBy(Constants.StartIndex)
    return path[Range(start: startIndex, end: path.endIndex)]
  }
  
  // MARK: - URL / Photo Downloading
  
  func fetchPhotoDataForLocation(location: Pin) {
    let boundingBox = BoundingBox(longitude: location.longitude as Double, latitude: location.latitude as Double)
    FlickrClient.searchByBoundingBox(boundingBox) { success, message, photoURLs in
      if success { // TODO: - add error handling
        dispatch_async(dispatch_get_main_queue()) {
          self.persistFlickrURLs(photoURLs!, forLocation: location)
        }
      } // TODO: - add alerts, remove pin if no photos exist for that location
      // remove var droppedPin from mapView in completion handler of alert view
    }
  }
  
  /// Select 21 random URLs, add them to CoreData context, initiaite downloading and saving of images
  ///- parameter urls: - Flickr URLS
  func persistFlickrURLs(urls: [String], forLocation location: Pin) {
    let photos = randomURLs(urls)
    savePhotoURLsToCoreData(photos, forLocation: location)
    downloadPhotoAlbumImageDataFromURLs(photos)
  }
  
  //MARK: - Core Data
  var sharedContext: NSManagedObjectContext {
    return CoreDataStackManager.sharedInstance.managedObjectContext!
  }
}

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
  func imageManagerDidFinishDownloadingImage()
  func locationHasImages(flag: Bool)
}

class ImageManager: NSObject, NSFetchedResultsControllerDelegate
{
  var selectedIndexes = [NSIndexPath]()
  var insertedIndexPaths: [NSIndexPath]?
  var deletedIndexPaths: [NSIndexPath]?
  
  var fileManager: NSFileManager {
    return NSFileManager.defaultManager()
  }

  var pin: Pin?
  
  /// This property serves as the data source for the PhotoAlbumViewController.photoAlbumCollectionView
  var dataSource = [ImageDataSource]()
  
  var downloadTasks = [NSURLSessionDownloadTask]()
  
  weak var delegate: ImageManagerDelegate?
  
  var imageIndicator: Bool? {
    didSet {
      delegate?.locationHasImages(imageIndicator!)
    }
  }
  
  
  /// Save URLs (local file paths) to CoreData
  /// - parameter urls: local file paths
  /// - parameter location: Pin (longitude and latitude data)
  func savePhotoURLsToCoreData(urls: [String], forLocation location: Pin) {
    for url in urls {
      let _ = Photo(photoURL: url, location: location, photoAlbumCount: urls.count, context: sharedContext)
    }
    dispatch_async(dispatch_get_main_queue()) {
      CoreDataStackManager.sharedInstance.saveContext()
    }
  }
  
  func downloadPhotoAlbumImageDataFromURLs(urls: [String]) {
    print("downloadPhotoAlbumImageDataFromURLs")
    for url in urls {
      let downloadTask = FlickrClient.downloadImageAtURL(url) { imageData in
        if let dataToWrite = imageData {
          dispatch_async(dispatch_get_main_queue()) {
            self.savePhotoToFileSystemAsData(dataToWrite, forFileName: self.imageURL(url))
            self.delegate?.imageManagerDidFinishDownloadingImage()
          }
        }
      }
      downloadTasks.append(downloadTask)
      print("download tasks: \(downloadTasks.count)")
    }
  }
  
  func cancelDownloadTasks() {
    for downloadTask in downloadTasks {
      downloadTask.cancel()
    }
  }
  
  /// - parameter urls: an array of URLs as strings
  /// - returns: an array of strings, max count 21, selected randomly from larger array
  private func randomURLs(urls: [String]) -> [String] {
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
  
  /// save data to file system as NSData object
  /// - parameter data: Data to be written to file system
  /// - parameter url: File name for file to be written
  func savePhotoToFileSystemAsData(data: NSData, forFileName url: String) {
    data.writeToFile(url, atomically: true)
    addFilePathToDataSource(url)
  }
  
  /// add file paths to the data source for use by the PhotoAlbumViewController
  ///  - parameter filePath:  local URL where image data is stored
  func addFilePathToDataSource(filePath: String) {
    let imageDataSource = ImageDataSource(imageFilePath: filePath)
    dataSource.append(imageDataSource)
  }
  
  /// delete files from the file system
  func deletePhotosForURLs(urls: [Photo]) {
    for url in urls {
      if let filePath = url.photo {
        do {
          try fileManager.removeItemAtPath(filePath)
        } catch let error as NSError {
          print(error.localizedDescription)
        }
      }
    }
  }
  
  /// Turn an external URL into a local URL
  private func imageURL(url: String) -> String {
    let truncatedPathComponent = imageFileName(url)
    let directoryPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    let pathArray = [directoryPath, truncatedPathComponent]
    let fileURL = NSURL.fileURLWithPathComponents(pathArray)?.path!
    return fileURL!
  }
  
  /// Make a file name from the Flickr URL
  private func imageFileName(path: String) -> String {
    let startIndex = path.endIndex.advancedBy(Constants.StartIndex)
    return path[Range(start: startIndex, end: path.endIndex)]
  }
  
  // MARK: - URL / Photo Downloading
  
  func fetchPhotoDataForLocation(location: Pin) {
    print("fetchPhotoDataForLocation")
    let boundingBox = BoundingBox(longitude: location.longitude as Double, latitude: location.latitude as Double)
    FlickrClient.searchByBoundingBox(boundingBox) { success, message, photoURLs in
      if success {
        dispatch_async(dispatch_get_main_queue()) {
          self.persistFlickrURLs(photoURLs!, forLocation: location)
        }
      }
      dispatch_async(dispatch_get_main_queue()) {
        self.imageIndicator = success
      }
    }
  }
  
  /// Select 21 random URLs, add them to CoreData context, initiaite downloading and saving of images
  /// - parameter urls: Array of external URLs
  func persistFlickrURLs(urls: [String], forLocation location: Pin) {
    let photos = randomURLs(urls)
    let urlsToPersist = photos.map { imageURL($0) }
    savePhotoURLsToCoreData(urlsToPersist, forLocation: location)
    downloadPhotoAlbumImageDataFromURLs(photos)
  }
  
  //MARK: - Core Data
  var sharedContext: NSManagedObjectContext {
    return CoreDataStackManager.sharedInstance.managedObjectContext!
  }
  
  lazy var fetchedResultsController: NSFetchedResultsController = {
    let fetchRequest = NSFetchRequest(entityName: "Photo")
    fetchRequest.sortDescriptors = []
    fetchRequest.predicate = NSPredicate(format: "location == %@", self.pin!)
    
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
      managedObjectContext: self.sharedContext,
      sectionNameKeyPath: nil,
      cacheName: nil)
    fetchedResultsController.delegate = self
    
    return fetchedResultsController
    }()
}

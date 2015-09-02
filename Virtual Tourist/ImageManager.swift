//
//  ImageManager.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/14/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import UIKit

protocol ImageManagerDelegate: class
{
  func imageManagerDidAddImageToCache(flag: Bool, atIndex index: Int)
}

class ImageManager
{
  func downloadPhotoDataFromURLs(urls: [String]) -> [NSData] {
    downloadingNewImages = true
    var album = [NSData]()
    dispatch_async(dispatch_get_global_queue(Constants.PhotoDownloadQOS, 0)) {
      for url in urls {
        let imageData = NSData(contentsOfURL: NSURL(string: url)!)
        album.append(imageData!)
      }
    }
    return album
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
  
  var downloadingNewImages: Bool? = false
  
  var downloadedPhotoCache = [UIImage]()
  
  weak var delegate: ImageManagerDelegate?
  
  func savePhotoAlbum(album: [NSData], withFileName fileName: [String]) {
    let manager = NSFileManager.defaultManager()
    let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
    for i in 0..<album.count {
      let path = fileName[i]
      let truncatedPathComponent = imageFileName(path)
      let filePath = url.URLByAppendingPathComponent(truncatedPathComponent).path!
      album[i].writeToFile(filePath, atomically: true)
      println("saved file to URL: \(filePath)")
      addDownloadedPhotoToCacheFromURL(filePath)
    }
    println("count in save album: \(downloadedPhotoCache.count)")
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
  
  ///:param: url - The full URL path as a String
  func addDownloadedPhotoToCacheFromURL(url: String) {
    println("called addPhotoToCacheFromURL")
    let path = imageURL(url)
    var image: UIImage?
    if let imageData = NSData(contentsOfURL: path) {
      image = UIImage(data: imageData)!
      downloadedPhotoCache.append(image!)
      delegate?.imageManagerDidAddImageToCache(true, atIndex: downloadedPhotoCache.count - 1)
      println("count in add to cache: \(downloadedPhotoCache.count)")
    }
  }
  
  func addPersistedPhotosToCache(urls: [Photo]) {
    println("called addPersistedPhotosToCache")
    for url in urls {
      if let photoURL = url.photo {
        let path = imageURL(photoURL)
        var image: UIImage?
        if let imageData = NSData(contentsOfURL: path) {
          image = UIImage(data: imageData)!
          downloadedPhotoCache.append(image!)
          delegate?.imageManagerDidAddImageToCache(true, atIndex: downloadedPhotoCache.count - 1)
          println("count in add to cache: \(downloadedPhotoCache.count)")
        }
      }
    }
    downloadingNewImages = false
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
}

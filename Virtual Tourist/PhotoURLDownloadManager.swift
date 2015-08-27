//
//  PhotoURLDownloadManager.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/14/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import Foundation

struct PhotoURLDownloadManager
{
  func downloadPhotoURLs(urls: [String]) -> [NSData] {
    var album = [NSData]()
    for url in urls {
      let imageData = NSData(contentsOfURL: NSURL(string: url)!)
      album.append(imageData!)
    }
    return album
  }
}
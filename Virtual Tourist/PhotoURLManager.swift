//
//  PhotoURLManager.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/12/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import Foundation

struct PhotoURLManager
{
  var urls: [String]
  
  func randomURLs() -> [String] {
    var urlArray = [String]()
    var defaultCount = 21
    if urls.count < 21 {
      defaultCount = urls.count
    }
    for var i = 0; i < defaultCount; i++ {
      let randomIndex = Int(arc4random_uniform(UInt32(urls.count)))
      let randomURL = urls[randomIndex]
      println("randomURL \(randomURL)")
      urlArray.append(randomURL)
    }
    return urlArray
  }
}

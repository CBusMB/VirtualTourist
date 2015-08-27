//
//  PhotoURLRandomizer.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/12/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import Foundation

struct PhotoURLRandomizer
{
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
}

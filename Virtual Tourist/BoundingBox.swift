//
//  BoundingBox.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/10/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

struct BoundingBox
{
  var bottomLeftLongitude: Double
  var bottomLeftLatitude: Double
  var topRightLongitude: Double
  var topRightLatitude: Double
  
  init(longitude: Double, latitude: Double) {
    bottomLeftLongitude = longitude - Flickr.BoundingBoxCoordinateAdjustment
    bottomLeftLatitude = latitude - Flickr.BoundingBoxCoordinateAdjustment
    topRightLongitude = longitude + Flickr.BoundingBoxCoordinateAdjustment
    topRightLatitude = latitude + Flickr.BoundingBoxCoordinateAdjustment
  }
  
  func boundingBoxForMethodParameters() -> String {
    println("\(bottomLeftLongitude), \(bottomLeftLatitude), \(topRightLongitude), \(topRightLatitude)")
    return "\(bottomLeftLongitude), \(bottomLeftLatitude), \(topRightLongitude), \(topRightLatitude)"
  }
}
//
//  VirtualTouristConstants.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/3/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//
import Foundation

struct Keys {
  static let Latitude = "latitude"
  static let Longitude = "longitude"
  static let LatitudeDelta = "latitudeDelta"
  static let LongitudeDelta = "longitudeDelta"
  static let ImageData = "image"
}

struct Flickr {
  static let APIValue = "bb74c0ee2d63bfcb1d090ac649c51a25"
  static let Secret = "96e030e2f88836d7"
  static let BaseURL = "https://api.flickr.com/services/rest"
  static let MethodKey = "method"
  static let MethodValue = "flickr.photos.search"
  static let APIKey = "api_key"
  static let DataFormatValue = "json"
  static let DataFormatKey = "format"
  static let BboxKey = "bbox"
  static let SafeSearchKey = "safe_search"
  static let ExtrasKey = "extras"
  static let NoJSONKey = "nojsoncallback"
  static let ExtrasValue = "url_m"
  static let SafeSearchValue = "1"
  static let NoJSONValue = "1"
  static let PerPageKey = "per_page"
  static let PerPageValue = "21"
  static let BoundingBoxCoordinateAdjustment = 0.09
  static let NoPhotosForLocation = "There are no photos for this location"
}

struct Constants {
  static let StartIndex = -16
  static let CellReuseIdentifier = "PhotoCell"
  static let PlaceholderCellReuseIdentifier = "PlaceholderCell"
  static let PhotoDownloadQOS = Int(QOS_CLASS_USER_INTERACTIVE.rawValue)
  static let RemoveSelectedPhotos = "Remove Selected Photos"
  static let RefreshPhotos = "Refresh Photos"
}
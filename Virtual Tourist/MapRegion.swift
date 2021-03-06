//
//  MapRegion.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/5/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import Foundation
import MapKit

/// Model class used to persist last viewed map location
class MapRegion: NSObject, NSCoding
{
  var latitude: CLLocationDegrees
  var longitude: CLLocationDegrees
  var latitudeDelta: CLLocationDegrees
  var longitudeDelta: CLLocationDegrees
  
  init(region: MKCoordinateRegion) {
    latitude = region.center.latitude
    longitude = region.center.longitude
    latitudeDelta = region.span.latitudeDelta
    longitudeDelta = region.span.longitudeDelta
  }
  
  required init?(coder unarchiver: NSCoder) {
    latitude = unarchiver.decodeObjectForKey(Keys.Latitude) as! CLLocationDegrees
    longitude = unarchiver.decodeObjectForKey(Keys.Longitude) as! CLLocationDegrees
    latitudeDelta = unarchiver.decodeObjectForKey(Keys.LatitudeDelta) as! CLLocationDegrees
    longitudeDelta = unarchiver.decodeObjectForKey(Keys.LongitudeDelta) as! CLLocationDegrees
    super.init()
  }
  
  func encodeWithCoder(archiver: NSCoder) {
    archiver.encodeObject(latitude, forKey: Keys.Latitude)
    archiver.encodeObject(longitude, forKey: Keys.Longitude)
    archiver.encodeObject(latitudeDelta, forKey: Keys.LatitudeDelta)
    archiver.encodeObject(longitudeDelta, forKey: Keys.LongitudeDelta)
  }
}
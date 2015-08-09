//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/3/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, NSFetchedResultsControllerDelegate
{
  @IBOutlet weak var mapView: MKMapView! {
    didSet {
     mapView.scrollEnabled = false
    }
  }
  
  var annotation: MKAnnotation?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    if let coordinate = annotation?.coordinate {
      let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
      
      let mapRegion = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
      mapView.setRegion(mapRegion, animated: false)
      let annotationPin = MKPointAnnotation()
      annotationPin.coordinate = coordinate
      mapView.addAnnotation(annotationPin)
    }
  }
}

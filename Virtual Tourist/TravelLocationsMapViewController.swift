//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/3/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate
{
  @IBOutlet weak var mapView: MKMapView! {
    didSet {
      mapView.delegate = self
      let longPress = UILongPressGestureRecognizer(target: self, action: "longPress:")
      longPress.minimumPressDuration = 0.5
      mapView.addGestureRecognizer(longPress)
    }
  }
  
  // MARK: - Saving to file system
  var regionToArchive: MKCoordinateRegion? {
    didSet {
      let newRegion = MapRegion(region: regionToArchive!)
      NSKeyedArchiver.archiveRootObject(newRegion, toFile: regionFilePath)
    }
  }
  
  var regionToUnarchive: MapRegion? {
    didSet {
      let center = CLLocationCoordinate2D(latitude: regionToUnarchive!.latitude, longitude: regionToUnarchive!.longitude)
      let span = MKCoordinateSpan(latitudeDelta: regionToUnarchive!.latitudeDelta, longitudeDelta: regionToUnarchive!.longitudeDelta)
      let region = MKCoordinateRegion(center: center, span: span)
      scrollMapViewToRegion(region)
    }
  }
  
  /// sets regionToArchive so that the last location is saved for the next time the app is opened
  func saveLastUserLocation(notification: NSNotification) {
    regionToArchive = mapView.region
  }
  
  var regionFilePath : String {
    let manager = NSFileManager.defaultManager()
    let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
    return url.URLByAppendingPathComponent("region").path!
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.rightBarButtonItem = editButtonItem()
    
    /// get the last map region from the file system
    if let savedRegion = NSKeyedUnarchiver.unarchiveObjectWithFile(regionFilePath) as? MapRegion {
      regionToUnarchive = savedRegion
    }
    
    let defaultCenter = NSNotificationCenter.defaultCenter()
    defaultCenter.addObserver(self, selector: "saveLastUserLocation:", name: "UIApplicationDidEnterBackgroundNotification", object: nil)
    
    var error: NSError?
    fetchedResultsController.performFetch(&error)
    addLocationPinsToMap()
  }
  
  // MARK: - View management
  
  override func setEditing(editing: Bool, animated: Bool) {
  }
  
  // MARK: - MKMapViewDelegate and related
  
  /// Save the current map view each time the map's region property is changed
  func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
    regionToArchive = mapView.region
  }
  
  func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
    var pinAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("PinAnnotationView") as? MKPinAnnotationView
    
    if pinAnnotationView == nil {
      pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "PinAnnotationView")
      pinAnnotationView!.canShowCallout = false
      pinAnnotationView!.pinColor = .Red
      pinAnnotationView?.animatesDrop = true
    }
    else {
      pinAnnotationView!.annotation = annotation
    }
    
    return pinAnnotationView
  }
  
  func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
    if editing {
      
    } else {
      let storyboard = UIStoryboard(name: "Main", bundle: nil)
      let photoAlbum = storyboard.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
      navigationController?.pushViewController(photoAlbum, animated: true)
    }
  }
  
  func scrollMapViewToRegion(region: MKCoordinateRegion) {
    mapView.setRegion(region, animated: false)
  }
  
  func addLocationPinsToMap() {
    let fetchedLocations = fetchedResultsController.fetchedObjects as! [Location]
    let annotations: [MKPointAnnotation] = fetchedLocations.map { (location) -> MKPointAnnotation in
      var annotation = MKPointAnnotation()
      annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude as Double, longitude: location.longitude as Double)
      return annotation
    }
    mapView.addAnnotations(annotations)
  }
  
  // MARK: - Gesture Recognizer
  
  func longPress(recognizer: UILongPressGestureRecognizer) {
    println("long press")
    if recognizer.state != .Began {
      return
    }
    let touchPoint = recognizer.locationInView(mapView)
    let touchCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
    let pinLocation = MKPointAnnotation()
    pinLocation.coordinate = touchCoordinate
    mapView.addAnnotation(pinLocation)
    addLocationToContextForCoordinate(touchCoordinate)
  }
  
  
  // MARK: - Core Data related methods and properties
  
  var sharedContext: NSManagedObjectContext {
    return CoreDataStackManager.sharedInstance.managedObjectContext!
  }
  
  /// Add the location to the CoreData context
  func addLocationToContextForCoordinate(coordinate: CLLocationCoordinate2D) {
    let locationAttributes = [
      Keys.Latitude : coordinate.latitude,
      Keys.Longitude : coordinate.longitude
    ]
    
    let location = Location(dictionary: locationAttributes, context: sharedContext)
    CoreDataStackManager.sharedInstance.saveContext()
  }
  
  lazy var fetchedResultsController: NSFetchedResultsController = {
    
    let fetchRequest = NSFetchRequest(entityName: "Location")
    fetchRequest.sortDescriptors = []
    
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
    fetchedResultsController.delegate = self
    
    return fetchedResultsController
    }()
}

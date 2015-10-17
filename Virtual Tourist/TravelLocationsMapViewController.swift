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
  
  var instructionView: UIView?
  
  var droppedPin: MKPointAnnotation?
  
  var imageManager: ImageManager!
  
  /// sets regionToArchive so that the last location is saved for the next time the app is opened
  func saveLastUserLocation(notification: NSNotification) {
    regionToArchive = mapView.region
  }
  
  var regionFilePath: String {
    let manager = NSFileManager.defaultManager()
    let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
    return url!.URLByAppendingPathComponent("region").path!
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.rightBarButtonItem = editButtonItem()
    
    // get the last map region from the file system
    if let savedRegion = NSKeyedUnarchiver.unarchiveObjectWithFile(regionFilePath) as? MapRegion {
      regionToUnarchive = savedRegion
    }
    
    let defaultCenter = NSNotificationCenter.defaultCenter()
    defaultCenter.addObserver(self, selector: "saveLastUserLocation:", name: "UIApplicationDidEnterBackgroundNotification", object: nil)
    do {
      try fetchedResultsController.performFetch()
    } catch let error as NSError {
      print(error)
    }
    addLocationPinsToMap()
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    // reset the ImageManager
    imageManager = ImageManager()
  }
  
  // MARK: - View management
  
  override func setEditing(editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
    if editing {
      let rectForInstructionView = viewToAnimateRect(viewHeightForOffset: 0.0)
      instructionView = DeleteInstructionsView(frame: rectForInstructionView)
    }
    animateView(view: instructionView!, forEditingState: editing)
  }
  
  /// Slide a view in or out to instruct the user on how to delete pins from the map
  func animateView(view viewToAnimate: UIView, forEditingState editing: Bool) {
    if editing {
      view.addSubview(viewToAnimate)
      UIView.animateWithDuration(0.55, delay: 0.0,
                      usingSpringWithDamping: 0.40,
                       initialSpringVelocity: 0.25,
                                     options: .CurveEaseIn,
                                  animations: { viewToAnimate.frame = self.viewToAnimateRect(viewHeightForOffset: viewToAnimate.frame.height) },
                                  completion: nil)
    } else {
      UIView.animateWithDuration(0.55,
        animations: { viewToAnimate.frame = self.viewToAnimateRect(viewHeightForOffset: 0.0) },
        completion: { (_) -> Void in viewToAnimate.removeFromSuperview() })
    }
  }
  
  /// - returns: The location and size of the animated view.
  /// - parameter viewHeightForOffset: Use this value to set the y position of the viewToAnimate relative to its super view.
  func viewToAnimateRect(viewHeightForOffset height: CGFloat) -> CGRect {
    return CGRect(x: view.frame.origin.x,
                  y: view.frame.height - height,
              width: view.frame.width,
              height: view.frame.height / 8)
  }
  
  // MARK: - MKMapViewDelegate and related
  
  /// Save the current map view each time the map's region property is changed
  func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    regionToArchive = mapView.region
  }
  
  func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
    var pinAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("PinAnnotationView") as? MKPinAnnotationView
    
    if pinAnnotationView == nil {
      pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "PinAnnotationView")
      pinAnnotationView!.canShowCallout = false
      pinAnnotationView!.pinColor = .Red
      pinAnnotationView?.animatesDrop = true
    } else {
      pinAnnotationView!.annotation = annotation
    }
    return pinAnnotationView
  }
  
  func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
    do {
      // perform a fetch so that we can be sure to get Pins that were just added
      try fetchedResultsController.performFetch()
    } catch let error as NSError {
      print(error)
    }
    let locations = fetchedResultsController.fetchedObjects as! [Pin]
    // Filter locations to get a location item that matches the selected annotationView.  Use .first to get the location from the array.
    let selectedLocation = locations.filter
      { $0.latitude == view.annotation!.coordinate.latitude && $0.longitude == view.annotation!.coordinate.longitude }
    if let pin = selectedLocation.first {
      if editing {
        if let urls = pin.photoAlbum {
          imageManager.deletePhotosForURLs(urls)
          sharedContext.deleteObject(pin)
          mapView.removeAnnotation(view.annotation!)
          CoreDataStackManager.sharedInstance.saveContext()
        }
      } else {
        if pin.photoAlbum?.count > 0 {
          pushToCollectionViewWithPin(pin)
        } else {
          imageManager.fetchPhotoDataForLocation(pin)
          pushToCollectionViewWithPin(pin)
        }
      }
    }
    mapView.deselectAnnotation(view.annotation, animated: false)
  }
  
  func pushToCollectionViewWithPin(pin: Pin) {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let photoAlbumViewController = storyboard.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
    photoAlbumViewController.pin = pin
    photoAlbumViewController.imageManager = self.imageManager
    navigationController?.pushViewController(photoAlbumViewController, animated: true)
  }
  
  func scrollMapViewToRegion(region: MKCoordinateRegion) {
    mapView.setRegion(region, animated: false)
  }
  
  func addLocationPinsToMap() {
    let fetchedLocations = fetchedResultsController.fetchedObjects as! [Pin]
    let annotations: [MKPointAnnotation] = fetchedLocations.map { (location) -> MKPointAnnotation in
      let annotation = MKPointAnnotation()
      annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude as Double, longitude: location.longitude as Double)
      return annotation
    }
    mapView.addAnnotations(annotations)
  }
  
  // MARK: - Gesture Recognizer
  
  func longPress(recognizer: UILongPressGestureRecognizer) {
    if recognizer.state != .Began {
      return
    }
    let touchPoint = recognizer.locationInView(mapView)
    let touchCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
    droppedPin = MKPointAnnotation()
    droppedPin!.coordinate = touchCoordinate
    mapView.addAnnotation(droppedPin!)
    addLocationToContextForCoordinate(touchCoordinate)
  }
  
  // MARK: - Core Data related methods and properties
  
  var sharedContext: NSManagedObjectContext {
    return CoreDataStackManager.sharedInstance.managedObjectContext!
  }
  
  /// Add the location to the CoreData context
  func addLocationToContextForCoordinate(coordinate: CLLocationCoordinate2D) {
    let _ = Pin(latitude: coordinate.latitude, longitude: coordinate.longitude, context: sharedContext)
    CoreDataStackManager.sharedInstance.saveContext()
  }
  
  lazy var fetchedResultsController: NSFetchedResultsController = {
    let fetchRequest = NSFetchRequest(entityName: "Pin")
    fetchRequest.sortDescriptors = []
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                      managedObjectContext: self.sharedContext,
                                                        sectionNameKeyPath: nil,
                                                                 cacheName: nil)
    fetchedResultsController.delegate = self
    return fetchedResultsController
  }()
}

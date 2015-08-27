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

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate
{
  var selectedIndexes = [NSIndexPath]()
  var insertedIndexPaths: [NSIndexPath]?
  var deletedIndexPaths: [NSIndexPath]?
  var updatedIndexPaths: [NSIndexPath]?
  
  // MARK: - Map View
  @IBOutlet weak var mapView: MKMapView! {
    didSet {
     mapView.scrollEnabled = false
    }
  }
  
  func configureMapView() {
    if let coordinate = annotation?.coordinate {
      let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
      let mapRegion = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
      mapView.setRegion(mapRegion, animated: false)
      let annotationPin = MKPointAnnotation()
      annotationPin.coordinate = coordinate
      mapView.addAnnotation(annotationPin)
    }
  }
  
  @IBOutlet weak var photoAlbumCollectionView: UICollectionView!
  @IBOutlet weak var refreshButton: UIBarButtonItem!
  
  var annotation: MKAnnotation?
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    configureMapView()
    var error: NSError?
    fetchedResultsController.performFetch(&error) // TODO: - Handle errors
    photoAlbumCollectionView.delegate = self
    photoAlbumCollectionView.dataSource = self
    photoAlbumCollectionView.registerClass(PhotoAlbumCollectionViewCell.self, forCellWithReuseIdentifier: Constants.CellReuseIdentifier)
    photoAlbumCollectionView.registerClass(PhotoAlbumCollectionViewCell.self, forCellWithReuseIdentifier: Constants.PlaceholderCellReuseIdentifier)
  }
  
  // MARK: - Core Data
  var sharedContext: NSManagedObjectContext {
    return CoreDataStackManager.sharedInstance.managedObjectContext!
  }
  
  lazy var fetchedResultsController: NSFetchedResultsController = {
    let locationLatitude: NSNumber = self.annotation!.coordinate.latitude
    let locationLongitude: NSNumber = self.annotation!.coordinate.longitude
    let fetchRequest = NSFetchRequest(entityName: "Pin")
    fetchRequest.sortDescriptors = []
    fetchRequest.predicate = NSCompoundPredicate(type: .AndPredicateType,
                                        subpredicates: [NSPredicate(format: "%K == %@", "latitude", locationLatitude),
                                                        NSPredicate(format: "%K == %@", "longitude", locationLongitude)])
    
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                      managedObjectContext: self.sharedContext,
                                                        sectionNameKeyPath: nil,
                                                                 cacheName: nil)
    fetchedResultsController.delegate = self
    
    return fetchedResultsController
    }()
  
  //MARK: - Collection View
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    let layout = UICollectionViewFlowLayout()
    layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    
    let width = floor(photoAlbumCollectionView.frame.size.width / 3)
    layout.itemSize = CGSize(width: width, height: width)
    photoAlbumCollectionView.collectionViewLayout = layout
  }
  
  func configureCell(cell: PhotoAlbumCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
    let pin = fetchedResultsController.fetchedObjects?.first as! Pin
    if let index = find(selectedIndexes, indexPath) {
      cell.alpha = 0.09
    } else {
      cell.alpha = 1.0
    }
    var image = UIImage()
    if let pinLocation = pin.photoAlbum {
      let imageURL = pinLocation[indexPath.item].photo
      image = ImageManager.getPhotoForURL(imageURL!)
      cell.imageView.image = image
    } else {
      
    }
  }

  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let pin = fetchedResultsController.fetchedObjects?.first as! Pin
    var numberOfCells = 11
    if let pinPhotoURLs = pin.photoAlbum {
      numberOfCells = pinPhotoURLs.count
      return numberOfCells
    }
    return numberOfCells
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let pin = fetchedResultsController.fetchedObjects?.first as! Pin
    var cell: PhotoAlbumCollectionViewCell!
//    if let index = find(selectedIndexes, indexPath) {
//      cell.alpha = 0.09
//    } else {
//      cell.alpha = 1.0
//    }

    if let photosForPin = pin.photoAlbum {
      println("photos for pin: \(photosForPin.count)")
      if photosForPin.count == 0 && indexPath.item == 0 {
        cell = photoAlbumCollectionView.dequeueReusableCellWithReuseIdentifier(Constants.PlaceholderCellReuseIdentifier, forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        cell.imageView = nil
        cell.backgroundView = activityView
        cell.bringSubviewToFront(cell.backgroundView!)
        activityView.startAnimating()
      } else {
        cell = photoAlbumCollectionView.dequeueReusableCellWithReuseIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
        let imageURL = photosForPin[indexPath.item].photo
        let image = ImageManager.getPhotoForURL(imageURL!)
        cell.imageView.image = image
      }
    }
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    let cell = photoAlbumCollectionView.cellForItemAtIndexPath(indexPath) as! PhotoAlbumCollectionViewCell
    if let index = find(selectedIndexes, indexPath) {
      selectedIndexes.removeAtIndex(index)
    } else {
      selectedIndexes.append(indexPath)
    }
    
    configureCell(cell, atIndexPath: indexPath)
  }
  
  // MARK: - Fetched Results Controller Delegate Methods
  
}

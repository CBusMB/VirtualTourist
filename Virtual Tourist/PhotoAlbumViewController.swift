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
    
    let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    layout.minimumLineSpacing = 5
    layout.minimumInteritemSpacing = 5
    
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
    }
    let imageView = UIImageView(image: image)
    imageView.contentMode = .ScaleToFill
    cell.backgroundView = imageView
  }

  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    // let sectionInfo = fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
    let pin = fetchedResultsController.fetchedObjects?.first as! Pin
    var numberOfCells = Int()
    if let pinPhotoURLs = pin.photoAlbum {
      numberOfCells = pinPhotoURLs.count
    }
    println("number Of Cells: \(numberOfCells)")
    return numberOfCells
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
    configureCell(cell, atIndexPath: indexPath)
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

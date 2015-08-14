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
  
  @IBOutlet weak var mapView: MKMapView! {
    didSet {
     mapView.scrollEnabled = false
    }
  }
  
  @IBOutlet weak var photoAlbumCollectionView: UICollectionView!
  @IBOutlet weak var refreshButton: UIBarButtonItem!
  
  var annotation: MKAnnotation?
  var location: Location?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    if let coordinate = annotation?.coordinate {
      let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
      
      let mapRegion = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
      mapView.setRegion(mapRegion, animated: false)
      let annotationPin = MKPointAnnotation()
      annotationPin.coordinate = coordinate
      mapView.addAnnotation(annotationPin)
      
      var error: NSError?
      fetchedResultsController.performFetch(&error) // TODO: - Handle errors
    }
  }

  // MARK: - Core Data
  var sharedContext: NSManagedObjectContext {
    return CoreDataStackManager.sharedInstance.managedObjectContext!
  }
  
  lazy var fetchedResultsController: NSFetchedResultsController = {
    let locationLatitude = self.location!.latitude as NSNumber
    let locationLongitude = self.location!.longitude as NSNumber
    let fetchRequest = NSFetchRequest(entityName: "Location")
    fetchRequest.sortDescriptors = []
    fetchRequest.predicate = NSCompoundPredicate(type: .AndPredicateType,
                                        subpredicates: [NSPredicate(format: "%K == %@", "latitude", "locationLatitude"),
                                                        NSPredicate(format: "%K == %@", "longitude", "locationLongitude")])
    
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
    
    let width = floor(photoAlbumCollectionView.frame.size.width/3)
    layout.itemSize = CGSize(width: width, height: width)
    photoAlbumCollectionView.collectionViewLayout = layout
  }
  
  func configureCell(cell: PhotoAlbumCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
    let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! PhotoAlbum
    if let index = find(selectedIndexes, indexPath) {
      cell.alpha = 0.09
    } else {
      cell.alpha = 1.0
    }
  }

  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let sectionInfo = fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
    
    println("number Of Cells: \(sectionInfo.numberOfObjects)")
    return sectionInfo.numberOfObjects
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

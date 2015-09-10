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

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate,ImageManagerDelegate
{
  var selectedIndexes = [NSIndexPath]()
  var insertedIndexPaths: [NSIndexPath]?
  var deletedIndexPaths: [NSIndexPath]?
  var updatedIndexPaths: [NSIndexPath]?
  var selectedLocationCoordinate: CLLocationCoordinate2D?
  weak var imageManager: ImageManager? {
    didSet {
      imageManager?.delegate = self
    }
  }
  
  var pin: Pin? {
    didSet {
      selectedLocationCoordinate = CLLocationCoordinate2DMake(pin?.latitude as! Double, pin?.longitude as! Double)
    }
  }
  
  // MARK: - Map View
  @IBOutlet weak var mapView: MKMapView! {
    didSet {
      mapView.scrollEnabled = false
      if let coordinate = selectedLocationCoordinate {
        let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let mapRegion = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        mapView.setRegion(mapRegion, animated: false)
        let annotationPin = MKPointAnnotation()
        annotationPin.coordinate = coordinate
        mapView.addAnnotation(annotationPin)
      }
    }
  }
  
  @IBOutlet weak var photoAlbumCollectionView: UICollectionView! {
    didSet {
      photoAlbumCollectionView.delegate = self
      photoAlbumCollectionView.dataSource = self
      photoAlbumCollectionView.registerClass(PhotoAlbumCollectionViewCell.self, forCellWithReuseIdentifier: Constants.CellReuseIdentifier)
      // photoAlbumCollectionView.registerClass(PhotoAlbumCollectionViewCell.self, forCellWithReuseIdentifier: Constants.PlaceholderCellReuseIdentifier)
    }
  }
  
  @IBOutlet weak var refreshButton: UIBarButtonItem!
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    var error: NSError?
    fetchedResultsController.performFetch(&error) // TODO: - Handle errors
  }
  
  // MARK: - Core Data
  var sharedContext: NSManagedObjectContext {
    return CoreDataStackManager.sharedInstance.managedObjectContext!
  }
  
  lazy var fetchedResultsController: NSFetchedResultsController = {
//    let locationLatitude: NSNumber = self.annotation!.coordinate.latitude
//    let locationLongitude: NSNumber = self.annotation!.coordinate.longitude
    let fetchRequest = NSFetchRequest(entityName: "Photo")
    fetchRequest.sortDescriptors = []
    fetchRequest.predicate = NSPredicate(format: "location == %@", self.pin!)
    
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                      managedObjectContext: self.sharedContext,
                                                        sectionNameKeyPath: nil,
                                                                 cacheName: nil)
    fetchedResultsController.delegate = self
    
    return fetchedResultsController
    }()
  
  //MARK: - ImageManagerDelegate
  func imageManagerDidAddImageToCache(flag: Bool, atIndex index: Int) {
    // let indexPath = NSIndexPath(forItem: index, inSection: photoAlbumCollectionView.numberOfSections())
    // photoAlbumCollectionView.insertItemsAtIndexPaths([indexPath])
  }
  
  func imageManagerDidPersistURLs(flag: Bool) {
    if flag {
      
    }
  }
  
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
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let sectionInfo = fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
    return sectionInfo.numberOfObjects
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    var cell = photoAlbumCollectionView.dequeueReusableCellWithReuseIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as!PhotoAlbumCollectionViewCell
    
    // if we have downloadTasks, assign a task to each cell
    if imageManager?.downloadTasks.count > 0 {
      cell.downloadTask = imageManager!.downloadTasks[indexPath.item]
    
      if let taskState = cell.downloadTask?.state {
        switch taskState {
        case .Running:
          cell = configurePlaceholderCell(cell)
        case .Suspended:
          cell = configurePlaceholderCell(cell)
        case .Canceling:
          cell = configurePlaceholderCell(cell)
          // if the task is completed, assign the image from the photo cache to the cell
        case .Completed:
          println("index path is \(indexPath.item), cache count is \(imageManager!.photoCache.count)")
          if imageManager?.photoCache.count > indexPath.item {
            if let cachedImage = imageManager?.photoCache[indexPath.item] {
              cell.backgroundView = nil
              cell.imageView.image = cachedImage
            }
          } else {
            cell = configurePlaceholderCell(cell)
          }
        default:
          cell = configurePlaceholderCell(cell)
        }
      }
    } else {
      println("index path is \(indexPath.item), cache count is \(imageManager!.photoCache.count)")
      if imageManager?.photoCache.count > indexPath.item {
        if let cachedImage = imageManager?.photoCache[indexPath.item] {
          cell.backgroundView = nil
          cell.imageView.image = cachedImage
        }
      } else {
        cell = configurePlaceholderCell(cell)
      }
    }
    
//    if let index = find(selectedIndexes, indexPath) {
//      cell.alpha = 0.09
//    } else {
//      cell.alpha = 1.0
//    }
    return cell
  }
  
  func configurePhotoCell(cell: PhotoAlbumCollectionViewCell) -> PhotoAlbumCollectionViewCell {
    return cell
  }
  
  func configurePlaceholderCell(cell: PhotoAlbumCollectionViewCell) -> PhotoAlbumCollectionViewCell {
    let activityView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    cell.imageView.image = nil
    cell.backgroundView = activityView
    cell.bringSubviewToFront(cell.backgroundView!)
    activityView.startAnimating()
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    let cell = photoAlbumCollectionView.cellForItemAtIndexPath(indexPath) as! PhotoAlbumCollectionViewCell
    if let index = find(selectedIndexes, indexPath) {
      selectedIndexes.removeAtIndex(index)
    } else {
      selectedIndexes.append(indexPath)
    }
    
    // configurePhotoCell(cell, atIndexPath: indexPath)
  }
  
  // MARK: - Fetched Results Controller Delegate Methods
  
}

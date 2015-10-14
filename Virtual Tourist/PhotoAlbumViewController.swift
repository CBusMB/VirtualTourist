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

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, ImageManagerDelegate
{
  var selectedIndexes = [NSIndexPath]()
  var insertedIndexPaths: [NSIndexPath]!
  var deletedIndexPaths: [NSIndexPath]!
  var updatedIndexPaths: [NSIndexPath]!
  var selectedLocationCoordinate: CLLocationCoordinate2D?
  
  weak var imageManager: ImageManager? {
    didSet {
      imageManager?.delegate = self
    }
  }
  
  var pin: Pin? {
    didSet {
      if pin != nil {
        selectedLocationCoordinate = CLLocationCoordinate2DMake(pin?.latitude as! Double, pin?.longitude as! Double)
      }
    }
  }
  
  /// This property is set via the delegate, if it is false we display an alert to the user
  var imageIndicator: Bool? {
    didSet {
      if imageIndicator == false {
        presentNoImagesAlert()
      }
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
    }
  }
  
  @IBOutlet weak var refreshButton: UIBarButtonItem!
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    fetchFromCoreData()
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    // imageManager?.cancelDownloadTasks()
  }
  
  func presentNoImagesAlert() {
    let noImagesContorller = UIAlertController(title: "No Images Found", message: "There are no images for the selected location", preferredStyle: .Alert)
    let okAction = UIAlertAction(title: "OK", style: .Default) { Void in self.navigationController?.popToRootViewControllerAnimated(true) }
    noImagesContorller.addAction(okAction)
    presentViewController(noImagesContorller, animated: true, completion: nil)
  }
  
  //MARK: - ImageManagerDelegate
//  func imageManagerDidFinishDownloadingImage() {
//    photoAlbumCollectionView.reloadData()
//  }
  
  func locationHasImages(flag: Bool) {
    imageIndicator = flag
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
  
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return self.fetchedResultsController.sections?.count ?? 0
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let sectionInfo = fetchedResultsController.sections![section]
    print("number of objects: \(sectionInfo.numberOfObjects)")
    return sectionInfo.numberOfObjects
  }
  
  func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    let cell = photoAlbumCollectionView.cellForItemAtIndexPath(indexPath) as! PhotoAlbumCollectionViewCell
    let activityIndicatorView = cell.activityView!
    if activityIndicatorView.isAnimating() {
      return false
    }
    return true
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = photoAlbumCollectionView.dequeueReusableCellWithReuseIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
    configureCell(cell, atIndexPath: indexPath)
    return cell
  }
  
  func configureCell(var cell: PhotoAlbumCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
    let fileManager = NSFileManager.defaultManager()
    let photo = fetchedResultsController.objectAtIndexPath(indexPath)
    cell.photoForCell = photo as? Photo
    if let localImageURL = imageManager?.imageURL((cell.photoForCell?.photo)!) {
      if fileManager.fileExistsAtPath(localImageURL) {
        cell.activityView?.stopAnimating()
        cell.imageView.image = UIImage(data: NSData(contentsOfFile: localImageURL)!)
      } else {
        let task = imageManager?.downloadPhotoAlbumImageDataFromURL((cell.photoForCell?.photo)!) { data in
          dispatch_async(dispatch_get_main_queue()) {
            cell.imageView.image = UIImage(data: data)
            cell.activityView?.stopAnimating()
          }
        }
        if let taskState = task?.state {
          switch (taskState) {
          case .Completed:
            cell.activityView?.stopAnimating()
            break
          case .Running, .Suspended, .Canceling:
            cell = configurePlaceholderCell(cell)
          }
        }
        cell.downloadTask = task
      }
    }
  }
  
  
  func configurePlaceholderCell(cell: PhotoAlbumCollectionViewCell) -> PhotoAlbumCollectionViewCell {
    cell.activityView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    cell.imageView.image = UIImage(named: "placeholder")
    cell.backgroundView = cell.activityView
    cell.bringSubviewToFront(cell.backgroundView!)
    cell.activityView!.startAnimating()
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    let cell = photoAlbumCollectionView.cellForItemAtIndexPath(indexPath) as! PhotoAlbumCollectionViewCell
    if let index = selectedIndexes.indexOf(indexPath) {
      selectedIndexes.removeAtIndex(index)
      cell.alpha = 1.0
    } else {
      selectedIndexes.append(indexPath)
      print("selected indexes: \(selectedIndexes.count)")
      cell.alpha = 0.5
    }
    configureCell(cell, atIndexPath: indexPath)
    toggleRefreshButtonTitle()
  }
  
  func toggleRefreshButtonTitle() {
    if selectedIndexes.count > 0 {
      refreshButton.title = Constants.RemoveSelectedPhotos
    } else {
      refreshButton.title = Constants.RefreshPhotos
    }
  }
  
  @IBAction func editPhotoCollection(sender: UIBarButtonItem) {
    print("editPhotoCollection \(selectedIndexes.count)")
    if selectedIndexes.isEmpty {
      imageManager?.deletePhotosForURLs((pin?.photoAlbum)!)
      deleteAllPhotoPathsFromCoreDataStore()
      imageManager?.fetchPhotoDataForLocation(pin!)
    } else {
      print("delete selected items")
      deleteSelectedPhotoPathsFromCoreDataStore()
      deletePhotosForSelectedIndexPaths()
    }
  }
  
  func deletePhotosForSelectedIndexPaths() {
    print("deletePhotosForSelectedIndexPaths")
    var selectedPhotos = [Photo]()
    for path in selectedIndexes {
      let cell = collectionView(photoAlbumCollectionView, cellForItemAtIndexPath: path) as! PhotoAlbumCollectionViewCell
      selectedPhotos.append(cell.photoForCell!)
    }
    imageManager?.deletePhotosForURLs(selectedPhotos)
  }
  
  // MARK: - Core Data
  
  func fetchFromCoreData() {
    do {
      try fetchedResultsController.performFetch()
      print("fetching")
    } catch let error as NSError {
      print(error.localizedDescription)
    } // TODO: - Handle errors
  }
  
  func deleteAllPhotoPathsFromCoreDataStore() {
    print("deleteAllPhotoPathsFromCoreDataStore")     
    for photo in fetchedResultsController.fetchedObjects as! [Photo] {
      sharedContext.deleteObject(photo)
    }
  }
  
  func deleteSelectedPhotoPathsFromCoreDataStore() {
    var photosToDelete = [Photo]()
    for indexPath in selectedIndexes {
      photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
    }
    print("photos to delete count: \(photosToDelete.count)")
    for photo in photosToDelete {
      sharedContext.deleteObject(photo)
    }
    
    selectedIndexes = [NSIndexPath]()
    CoreDataStackManager.sharedInstance.saveContext()
  }
  
  var sharedContext: NSManagedObjectContext {
    return CoreDataStackManager.sharedInstance.managedObjectContext!
  }
  
  lazy var fetchedResultsController: NSFetchedResultsController = {
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
  
  // MARK: - Fetched Results Controller Delegate Methods
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    insertedIndexPaths = [NSIndexPath]()
    deletedIndexPaths = [NSIndexPath]()
    updatedIndexPaths = [NSIndexPath]()
  }
  
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    switch type {
    case .Insert:
      print("insert")
      insertedIndexPaths.append(newIndexPath!)
      break
    case .Delete:
      print("Delete an item: \(deletedIndexPaths.count)")
      deletedIndexPaths.append(indexPath!)
      break
    case .Update:
      print("Update an item.")
      updatedIndexPaths.append(indexPath!)
      break
    default:
      break
    }
  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    
    print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
    
    photoAlbumCollectionView.performBatchUpdates ({() -> Void in
      
      for indexPath in self.insertedIndexPaths {
        self.photoAlbumCollectionView.insertItemsAtIndexPaths([indexPath])
      }
      
      for indexPath in self.deletedIndexPaths {
        self.photoAlbumCollectionView.deleteItemsAtIndexPaths([indexPath])
      }
      
      for indexPath in self.updatedIndexPaths {
        self.photoAlbumCollectionView.reloadItemsAtIndexPaths([indexPath])
      }
      
      }, completion: nil)
  }
  
}

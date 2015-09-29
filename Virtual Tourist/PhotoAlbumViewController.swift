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

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, ImageManagerDelegate, NSFetchedResultsControllerDelegate
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
  func imageManagerDidFinishDownloadingImage() {
    print("imageManagerDidFinishDownloadingImage")
    photoAlbumCollectionView.reloadData()
  }
  
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
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let sectionInfo = fetchedResultsController.sections![section]
    print("number of objects: \(sectionInfo.numberOfObjects)")
    return sectionInfo.numberOfObjects
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = photoAlbumCollectionView.dequeueReusableCellWithReuseIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
    configurePhotoCell(cell, atIndexPath: indexPath)
    
    

    return cell
  }
  
  func configurePhotoCell(cell: PhotoAlbumCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
    let fileManager = NSFileManager.defaultManager()
    let photoURL = fetchedResultsController.objectAtIndexPath(indexPath)
    cell.photoURL = photoURL as? Photo
    if let localImageURL = imageManager?.imageURL("\(cell.photoURL)") {
      if fileManager.fileExistsAtPath(localImageURL) {
        cell.imageView.image = UIImage(contentsOfFile: localImageURL)
      } else {
        cell.downloadTask = imageManager?.downloadPhotoAlbumImageDataFromURL("\(cell.photoURL)")
        switch cell.downloadTask {
        case .Running:
          cell = configurePlaceholderCell(cell)
          case
        }
      }
    }
    if let _ = selectedIndexes.indexOf(indexPath) {
      cell.backgroundView!.alpha = 0.05
    } else {
      cell.backgroundView!.alpha = 1.0
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
    toggleRefreshButtonTitle()
    let cell = photoAlbumCollectionView.cellForItemAtIndexPath(indexPath) as! PhotoAlbumCollectionViewCell
    if let index = selectedIndexes.indexOf(indexPath) {
      selectedIndexes.removeAtIndex(index)
    } else {
      selectedIndexes.append(indexPath)
    }
    
    // configurePhotoCell(cell, atIndexPath: indexPath)
  }
  
  func toggleRefreshButtonTitle() {
    if refreshButton.title == Constants.RemoveSelectedPhotos {
      refreshButton.title = Constants.RefreshPhotos
    } else {
      refreshButton.title = Constants.RemoveSelectedPhotos
    }
  }
  
  @IBAction func editPhotoCollection(sender: UIBarButtonItem) {
    if sender.title == Constants.RefreshPhotos {
      imageManager?.cancelDownloadTasks()
      imageManager?.resetDataSourceDownloadTasksAndCounter()
      imageManager?.deletePhotosForURLs((pin?.photoAlbum)!)
      deleteAllPhotos()
      imageManager?.fetchPhotoDataForLocation(pin!)
    } else {
      
    }
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
  
  func deleteAllPhotos() {
    for photo in fetchedResultsController.fetchedObjects as! [Photo] {
      sharedContext.deleteObject(photo)
    }
  }
  
  func deleteSelectedPhotos() {
    var photosToDelete = [Photo]()
    
    for indexPath in selectedIndexes {
      photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
    }
    
    for photo in photosToDelete {
      sharedContext.deleteObject(photo)
    }
    
    selectedIndexes = [NSIndexPath]()
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
      print("Insert an item")
      insertedIndexPaths.append(newIndexPath!)
      break
    case .Delete:
      print("Delete an item")
      deletedIndexPaths.append(indexPath!)
      break
    case .Update:
      print("Update an item.")
      updatedIndexPaths.append(indexPath!)
      break
    case .Move:
      print("Move an item. We don't expect to see this in this app.")
      break
    }
  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    
    print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
    
    photoAlbumCollectionView.performBatchUpdates({() -> Void in
      
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

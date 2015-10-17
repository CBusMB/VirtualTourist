//
//  PhotoAlbumCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/13/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import UIKit

class PhotoAlbumCollectionViewCell: UICollectionViewCell
{
  override init(frame: CGRect) {
    super.init(frame: frame)
    imageView = UIImageView(frame: contentView.bounds)
    imageView.contentMode = .ScaleToFill
    contentView.addSubview(imageView)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  var imageView: UIImageView!
  var downloadTask: NSURLSessionDownloadTask? {
    didSet {
      if let taskToCancel = oldValue {
        taskToCancel.cancel()
      }
    }
  }
  	
  var activityView: UIActivityIndicatorView?
  var photoForCell: Photo?
}

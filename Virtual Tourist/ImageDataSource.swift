//
//  ImageDataSource.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 9/19/15.
//  Copyright © 2015 Crest Technologies. All rights reserved.
//

import Foundation
import UIKit

struct ImageDataSource {
  var imageFilePath: String?
  var image: UIImage {
    if UIImage(contentsOfFile: imageFilePath!) != nil {
      return UIImage(contentsOfFile: imageFilePath!)!
    } else {
      return UIImage(named: "placeholder")!
    }    
  }
}

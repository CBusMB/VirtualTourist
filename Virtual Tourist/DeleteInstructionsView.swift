//
//  DeleteInstructionsView.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/7/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//

import UIKit

class DeleteInstructionsView: UIView
{
  struct TextAttributes {
    static let attributes = [
      NSStrokeColorAttributeName: UIColor.blackColor(),
      NSForegroundColorAttributeName: UIColor.yellowColor(),
      NSFontAttributeName: UIFont(name: "HelveticaNeue", size: 22)!,
      NSStrokeWidthAttributeName : -1.0
    ]
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  func configureView() {
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
    backgroundColor = UIColor.redColor()
    label.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
    label.backgroundColor = UIColor.clearColor()
    label.textAlignment = .Center
    let labelText = "Tap Pins To Delete"
    label.attributedText = NSAttributedString(string: labelText, attributes: TextAttributes.attributes)
    addSubview(label)
  }
  
}

//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Matthew Brown on 8/9/15.
//  Copyright (c) 2015 Crest Technologies. All rights reserved.
//
import UIKit

class FlickrClient
{
  class func searchByBoundingBox(boundingBox: BoundingBox, completionHandler: (success: Bool, message: String?, flickrPhotoURLs: [String]?) -> Void) {
    let methodArguments = [
      Flickr.MethodKey : Flickr.MethodValue,
      Flickr.APIKey : Flickr.APIValue,
      Flickr.BboxKey : boundingBox.boundingBoxForMethodParameters(),
      Flickr.SafeSearchKey : Flickr.SafeSearchValue,
      Flickr.ExtrasKey : Flickr.ExtrasValue,
      Flickr.DataFormatKey : Flickr.DataFormatValue,
      Flickr.NoJSONKey : Flickr.NoJSONValue
    ]
    let url = NSURL(string: Flickr.BaseURL + escapedParameters(methodArguments))
    let request = NSURLRequest(URL: url!)
    let session = NSURLSession.sharedSession()
    let task = session.dataTaskWithRequest(request) { data, response, error in
      if error != nil {
        completionHandler(success: false, message: error?.localizedDescription, flickrPhotoURLs: nil)
      } else {
        do {
          let jsonData = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
          if let parsedJson = jsonData {
            let results = parsedJson["photos"] as! NSDictionary
            if results["total"] as! String != "0" {
              let photoURLs = results["photo"] as! [NSDictionary]
              let urls = photoURLs.map { $0["url_m"] as! String }
              completionHandler(success: true, message: nil, flickrPhotoURLs: urls)
            } else {
              completionHandler(success: false, message: error?.localizedDescription, flickrPhotoURLs: nil)
            }
          }
        } catch let jsonError as NSError {
            completionHandler(success: false, message: jsonError.localizedDescription, flickrPhotoURLs: nil)
        }
      }
    }
    task.resume()
  }
  
  class func downloadImageAtURL(url: String, downloadComplete: (imageData: NSData?) -> Void) -> NSURLSessionDownloadTask {
    let session = NSURLSession.sharedSession()
    let downloadTask = session.downloadTaskWithURL(NSURL(string: url)!) { (location, _, error) -> Void in
      if let downloadedImageData = NSData(contentsOfURL: location!) {
        downloadComplete(imageData: downloadedImageData)
      } else {
        // TODO: - handle error
        print("error in downloadTaskWithURL completion handler")
      }
    }
    downloadTask.resume()
    return downloadTask
  }
    
  
  // from Udacity networking course
  private class func escapedParameters(parameters: [String : AnyObject]) -> String {
    var urlVars = [String]()
    for (key, value) in parameters {
      let stringValue = "\(value)"
      let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
      urlVars += [key + "=" + "\(escapedValue!)"]
    }
    return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
  }
}
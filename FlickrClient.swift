//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Daniel McAteer on 8/26/17.
//  Copyright © 2017 Daniel McAteer. All rights reserved.
//

import Foundation

class FlickrClient {
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    // MARK: Keys
    
    private static let flickrURL = "https://api.flickr.com/services/rest/"
    private static let apiKey = "7d0a6e70689aa5b77a314669ce705530"
    private static let searchMethod = "flickr.photos.search"
    private static let format = "json"
    private static let searchRangeKM = 10
    
    // MARK: Get Image Function
    
    func getFlickrImages(lat: Double, long: Double, completionHandler: @escaping (_ success: Bool, _ flickrImages: [FlickrImage]?) -> Void) {
        
        let request = NSMutableURLRequest(url: URL(string: "\(FlickrClient.flickrURL)?method=\(FlickrClient.searchMethod)&format=\(FlickrClient.format)&api_key=\(FlickrClient.apiKey)&lat=\(lat)&lon=\(long)&radius=\(FlickrClient.searchRangeKM)")!)
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if error != nil {
                
                print("The request failed due to error: \(error).")
                return
            }
            
            let range = Range(uncheckedBounds: (14, data!.count - 1))
            let newData = data?.subdata(in: range)
            
            if let json = try? JSONSerialization.jsonObject(with: newData!) as? [String: Any],
                let photosDict = json?["photos"] as? [String: Any],
                let photos = photosDict["photo"] as? [Any] {
                
                var flickrArray: [FlickrImage] = []
                
                for photo in photos {
                    
                    if let flickrImage = photo as? [String:Any],
                        let id = flickrImage["id"] as? String,
                        let secret = flickrImage["secret"] as? String,
                        let server = flickrImage["server"] as? String,
                        let farm = flickrImage["farm"] as? Int {
                        flickrArray.append(FlickrImage(id: id, secret: secret, server: server, farm: farm))
                    }
                }
                
                completionHandler(true, flickrArray)
            
            } else {
                
                completionHandler(false, nil)
            }
        }
        
        task.resume()
    }
}

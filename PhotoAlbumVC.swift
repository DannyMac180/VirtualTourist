//
//  PhotoAlbumVC.swift
//  Virtual Tourist
//
//  Created by Daniel McAteer on 8/26/17.
//  Copyright © 2017 Daniel McAteer. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumVC: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var noPhotosLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var flickrClient = FlickrClient.sharedInstance()
    
    var coordinateSelected: CLLocationCoordinate2D!
    let spacingBetweenItems:CGFloat = 5
    let totalCellCount:Int = 25
    
    var coreDataPin: Pin!
    var photos: [Photo] = []
    var selectedToDelete: [Int] = [] {
        
        didSet {
            
            if selectedToDelete.count > 0 {
                
                newCollectionButton.setTitle("Remove Selected Pictures", for: .normal)
                
            } else {
                
                newCollectionButton.setTitle("New Collection", for: .normal)
            }
        }
    }
    
    func getCoreDataStack() -> CoreDataStack {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.stack
    }
    
    func preloadSavedPhoto() -> [Photo]? {
        
        do {
            
            let managedObjectContext = getCoreDataStack().context
            
            let photosFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
            photosFetch.sortDescriptors = []
            photosFetch.predicate = NSPredicate(format: "pin = %@", argumentArray: [coreDataPin!])
            
            do {
                
                photos = try managedObjectContext.fetch(photosFetch) as! [Photo]
                photos = photos.sorted(by: {$0.index < $1.index})
                return photos
                
            } catch {
                
                fatalError("Failed to fetch photos: \(error)")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let savedPhoto = preloadSavedPhoto()
        if savedPhoto != nil && savedPhoto?.count != 0 {
            photos = savedPhoto!
            showSavedResult()
            
        } else {
            
            showNewResult()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Flow Layout
        
        let space: CGFloat = 3.0
        let dimension = (self.view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = spacingBetweenItems
        flowLayout.minimumLineSpacing = spacingBetweenItems
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        //Collection View
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //Button & Label
        
        newCollectionButton.isHidden = false
        noPhotosLabel.isHidden = true
        
        //Add To Map
        
        collectionView.allowsMultipleSelection = true
        addAnnotationToMap()
        
    }
    

    @IBAction func newCollectionAction(_ sender: Any) {
        
        if selectedToDelete.count > 0 {
            
            removeSelectedPicturesAtCoreData()
            unselectAllSelectedCollectionViewCell()
            photos = preloadSavedPhoto()!
            showSavedResult()
            
        } else {
            
            showNewResult()
        }
    }
    
    func unselectAllSelectedCollectionViewCell() {
        
        for indexPath in collectionView.indexPathsForSelectedItems! {
            
            collectionView.deselectItem(at: indexPath, animated: false)
            collectionView.cellForItem(at: indexPath)?.contentView.alpha = 1
        }
    }
    
    func removeSelectedPicturesAtCoreData() {
        
        for index in 0..<photos.count {
            
            if selectedToDelete.contains(index) {
                
                getCoreDataStack().context.delete(photos[index])
            }
        }
        
        do {
            try getCoreDataStack().saveContext()
            
        } catch {
            
            print("Remove Core Data Photo Failed")
        }
        
        selectedToDelete.removeAll()
    }
    
    func showSavedResult() {
        
        DispatchQueue.main.async {
            
            self.collectionView.reloadData()
        }
    }
    
    func showNewResult() {
        
        newCollectionButton.isEnabled = false
        
        deleteExistingCoreDataPhoto()
        photos.removeAll()
        collectionView.reloadData()
        
        getFlickrImagesRandomResult { (flickrImages) in
            
            if flickrImages != nil {
                
                DispatchQueue.main.async {
                    
                    self.addCoreData(flickrImages: flickrImages!, coreDataPin: self.coreDataPin)
                    self.photos = self.preloadSavedPhoto()!
                    self.showSavedResult()
                    self.newCollectionButton.isEnabled = true
                }
            }
        }
    }
    
    func addCoreData(flickrImages:[FlickrImage], coreDataPin:Pin) {
        
        for image in flickrImages {
            
            do {
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let stack = delegate.stack
                let photo = Photo(index: flickrImages.index{$0 === image}!, imageUrl: image.imageURLString(), imageData: nil, context: stack.context)
                photo.pin = coreDataPin
                try stack.saveContext()
                
            } catch {
                
                print("Add Core Data Failed")
            }
        }
    }

    
    func getFlickrImagesRandomResult(completion: @escaping (_ result:[FlickrImage]?) -> Void) {
        
        var result:[FlickrImage] = []
        flickrClient.getFlickrImages(lat: coordinateSelected.latitude, long: coordinateSelected.longitude) { (success, flickrImages) in
            if success {
                
                if flickrImages!.count > self.totalCellCount {
                    var randomArray:[Int] = []
                    
                    while randomArray.count < self.totalCellCount {
                        
                        let random = arc4random_uniform(UInt32(flickrImages!.count))
                        if !randomArray.contains(Int(random)) { randomArray.append(Int(random)) }
                    }
                    
                    for random in randomArray {
                        
                        result.append(flickrImages![random])
                    }
                    
                    completion(result)
                    
                } else {
                    
                    completion(flickrImages!)
                }
                
            } else {
                completion(nil)
            }
        }
    }
    
    func addAnnotationToMap() {
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinateSelected
        mapView.addAnnotation(annotation)
        mapView.showAnnotations([annotation], animated: true)
    }
    
    func deleteExistingCoreDataPhoto() {
        
        for image in photos {
            
            getCoreDataStack().context.delete(image)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! CollectionViewCell
        
        cell.activityIndicator.startAnimating()
        cell.initWithPhoto(photos[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = UIScreen.main.bounds.width / 3 - spacingBetweenItems
        let height = width
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return spacingBetweenItems
    }
    
    func selectedToDeleteFromIndexPath(_ indexPathArray: [IndexPath]) -> [Int] {
        var selected:[Int] = []
        
        for indexPath in indexPathArray {
            
            selected.append(indexPath.row)
        }
        return selected
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        selectedToDelete = selectedToDeleteFromIndexPath(collectionView.indexPathsForSelectedItems!)
        let cell = collectionView.cellForItem(at: indexPath)
        
        DispatchQueue.main.async {
            
            cell?.contentView.alpha = 0.5
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        selectedToDelete = selectedToDeleteFromIndexPath(collectionView.indexPathsForSelectedItems!)
        let cell = collectionView.cellForItem(at: indexPath)
        
        DispatchQueue.main.async {
            
            cell?.contentView.alpha = 1
        }
    }
    
}


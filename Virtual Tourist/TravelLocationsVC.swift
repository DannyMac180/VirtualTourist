//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Daniel McAteer on 8/26/17.
//  Copyright © 2017 Daniel McAteer. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class TravelLocationsVC: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinsLabel: UILabel!
    
    var gestureBegin: Bool = false
    var editMode: Bool = false
    var pins: [Pin] = []
    
    func getCoreDataStack() -> CoreDataStack {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.stack
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deletePinsLabel.isHidden = true
        
        setRightBarButtonItem()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let managedObjectContext = getCoreDataStack().context
        
        let pinsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        do {
            
            pins = try managedObjectContext.fetch(pinsFetch) as! [Pin]
        
        } catch {
            
            fatalError("Failed to fetch employees: \(error)")
        
        }
        
        for pin in pins {
            
            let coord = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            addAnnotationToMap(fromCoord: coord)
            
        }
    }
    
    func setRightBarButtonItem() {
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        gestureBegin = true
        return true
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if !editMode {
            
            performSegue(withIdentifier: "showPhotosVC", sender: view.annotation?.coordinate)
            
            mapView.deselectAnnotation(view.annotation, animated: true)
            
        } else {
            
            removeCoreData(of: view.annotation!)
            
            mapView.removeAnnotation(view.annotation!)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pinView")
        pinView.animatesDrop = true
        
        return pinView
    }
    
    @IBAction func longPressGestureAction(_ sender: Any) {
        
        if gestureBegin {
            
            let gestureRecognizer = sender as! UILongPressGestureRecognizer
            let location = gestureRecognizer.location(in: mapView)
            addAnnotationToMap(fromPoint: location)
            gestureBegin = false
            
        }
    }
    
    func addAnnotationToMap(fromPoint: CGPoint) {
        
        let coordToAdd = mapView.convert(fromPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordToAdd
        saveCoreData(of: annotation)
        mapView.addAnnotation(annotation)
        
    }
    
    func addAnnotationToMap(fromCoord: CLLocationCoordinate2D) {
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = fromCoord
        mapView.addAnnotation(annotation)
    }
    
    func saveCoreData(of: MKPointAnnotation) {
        
        let coord = of.coordinate
        let managedContext = getCoreDataStack().context
        let entity = NSEntityDescription.entity(forEntityName: "Pin", in: managedContext)!
        let pin = NSManagedObject(entity: entity, insertInto: managedContext) as! Pin
        pin.setValue(coord.latitude, forKey: "latitude")
        pin.setValue(coord.longitude, forKey: "longitude")
        
        do {
            try getCoreDataStack().saveContext()
            pins.append(pin)
            
        } catch {
            print("Add Core Data Failed")
        }
    }
    
    func removeCoreData(of: MKAnnotation) {
        
        let coord = of.coordinate
        
        for pin in pins {
            
            if pin.latitude == coord.latitude && pin.longitude == coord.longitude {
                
                do {
                    
                    getCoreDataStack().context.delete(pin)
                    try getCoreDataStack().saveContext()
                    
                } catch {
                    
                    print("Remove Core Data Failed")
                }
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showPhotosVC" {
            
            let destination = segue.destination as! PhotoAlbumVC
            let coord = sender as! CLLocationCoordinate2D
            destination.coordinateSelected = coord
            
            for pin in pins {
                
                if pin.latitude == coord.latitude && pin.longitude == coord.longitude {
                    
                    destination.coreDataPin = pin
                    break
                }
            }
            
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        
        deletePinsLabel.isHidden = !editing
        editMode = editing
    }
    
}


//
//  ViewController.swift
//  Visit
//
//  Created by Bernd Plontsch on 23.10.18.
//  Copyright © 2018 Bernd Plontsch. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications
import MapKit

class ViewController: UIViewController {
    
    var locationManager:CLLocationManager = CLLocationManager()
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var visitsSwitch: UISwitch!
    @IBOutlet weak var historyButton: UIButton!
    
    var visits = [Visit]() {
        didSet{
            self.historyButton.setTitle("\(visits.count)", for: UIControl.State.normal)
            Storage.save(state: visits)
        }
    }
    
    func restoreVisits() {
        visits = Storage.load() ?? [Visit]()
    }
    
    func addVisit(visit:Visit) {
        visits.insert(visit, at: 0)
        //visits.append(visit)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHistory" {
            let visitsTableViewController = segue.destination as! VisitsTable
            visitsTableViewController.visits = self.visits
        }
    }
    
    @IBAction func unwindToMap(_ unwindSegue: UIStoryboardSegue) {
        //let sourceViewController = unwindSegue.source
        print("unwind")
        restoreVisits()
        // Use data from the view controller which initiated the unwind segue
    }
    
    @IBAction func didTapVisitsSwitch(_ sender: UISwitch) {
        if sender.isOn {
            locationManager.startMonitoringVisits()
            print("Start")
        } else {
            locationManager.stopMonitoringVisits()
            print("Stop")
        }
    }
    
    @IBAction func didTapCheckCurrentVisit(_ sender: Any) {
        guard let location = locationManager.location else {
            print("No location")
            return
        }
        findNearybSupermarket(visitCoordinate:location.coordinate, completion: {(visit) in
            self.sendVisitNotification(visit: visit, identifier: "nearbySupermarket\(Date())", interval: 1)
            self.addAnnotation(coordinate: visit.locationCoordinate(), title: visit.title)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocation()
        setupNotifications()
        showCurrentLocation()
        restoreVisits()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func showCurrentLocation() {
        if let userLocation = locationManager.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 400, longitudinalMeters: 400)
            mapView.setRegion(viewRegion, animated: true)
        }
    }
    
    func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.badge, .sound, .alert]) { (granted, error) in print ("granted \(granted)") }
        UNUserNotificationCenter.current().delegate = self
    }
    
    func setupLocation() {
        locationManager.delegate = self
        print("Location Permissions \(CLLocationManager.authorizationStatus())")
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.startMonitoringVisits()
    }

}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        print("Did Visit \(visit.arrivalDate) \(visit.departureDate)")
        sendVisitNotification()
        if visit.departureDate == NSDate.distantFuture {
            // arrived, not yet left
            findNearybSupermarket(visitCoordinate:visit.coordinate, completion: {(visit) in
                self.sendVisitNotification(visit: visit, identifier: "nearbySupermarket\(Date())", interval: 1)
                self.addAnnotation(coordinate: visit.locationCoordinate(), title: visit.title)
                self.addVisit(visit: visit)
            })
        }
    }
    
    func findNearybSupermarket(visitCoordinate:CLLocationCoordinate2D, completion: @escaping (Visit) -> Void) {
        print("Find near \(visitCoordinate)")
        let radiusInMeters = 100.0
        let query:String = "supermarket"
        
        let request:MKLocalSearch.Request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let region:MKCoordinateRegion = MKCoordinateRegion(center: visitCoordinate, latitudinalMeters: radiusInMeters, longitudinalMeters: radiusInMeters)
        request.region = region
        
        let search:MKLocalSearch = MKLocalSearch(request: request)
        
        search.start { (response:MKLocalSearch.Response?, error:Error?) in
            if let items = response?.mapItems {
                var results = [Visit]()
                for item in items {
                    var title = item.name ?? "No Title"
                    let distance = item.placemark.coordinate.distanceTo(otherLocation: visitCoordinate)
                    let inferredIsCurrentLocation = distance < 90.0 ? true : false
                    let systemIsCurrentLocation = item.isCurrentLocation
                    title = inferredIsCurrentLocation == true ? "📍\(title)" : title
                    if systemIsCurrentLocation == true {
                        title = "\(title) IS SYSTEM CURRENT"
                    }
                    let visitResult = Visit(title: title, distance: distance, isCurrentLocation: inferredIsCurrentLocation, latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
                    results.append(visitResult)
                }
                
                results.sort(by: { (resultA, resultB) -> Bool in
                    return resultA.distance < resultB.distance
                })
                results.sort(by: { (resultA, resultB) -> Bool in
                    return resultA.isCurrentLocation
                })
                
                print("Results \(results)")
                if let firstLocationResult = results.first {
                    completion(firstLocationResult)
                }
            } else {
              print("No Results")
            }
        }
    }
    
    func sendVisitNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Vist"
        content.body = "Here"
        content.categoryIdentifier = "visitWithMap"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: NSDate().description, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func sendVisitNotification(visit:Visit, identifier:String, interval:TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = visit.title
        content.body = visit.distance.distanceString()
        content.categoryIdentifier = "visitWithMap"
        content.userInfo = ["latitude":visit.latitude, "longitude":visit.longitude]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
    
        let request = UNNotificationRequest(identifier: NSDate().description, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func addAnnotation(coordinate:CLLocationCoordinate2D, title:String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        self.mapView.addAnnotation(annotation)
        self.mapView.showAnnotations([annotation], animated: true)
    }
}

extension Double {
    func distanceString()->String {
        let meters = Measurement(value: self, unit: UnitLength.meters)
        let distanceInUserMetric = MeasurementFormatter().string(from: meters)
        return distanceInUserMetric
    }
}

extension CLLocationCoordinate2D {
    func distanceTo(otherLocation:CLLocationCoordinate2D)->Double {
        let thisLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let otherLocation = CLLocation(latitude: otherLocation.latitude, longitude: otherLocation.longitude)
        let distance = thisLocation.distance(from: otherLocation)
        return distance
    }
}

extension ViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
    }
}

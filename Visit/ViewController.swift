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

struct LocationResult {
    let title:String
    let distance:Double
    let isCurrentLocation:Bool
    let latitude:Double
    let longitude:Double
    func locationCoordinate()->CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
}

class ViewController: UIViewController {
    
    var locationManager:CLLocationManager = CLLocationManager()
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var visitsSwitch: UISwitch!
    
    @IBOutlet weak var visitsSwitchEffectView: UIVisualEffectView!
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
        findNearybSupermarket(visitCoordinate: location.coordinate)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocation()
        setupNotifications()
        visitsSwitchEffectView.layer.cornerRadius = visitsSwitchEffectView.bounds.height / 2.0
        visitsSwitchEffectView.layer.masksToBounds = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showCurrentLocation()
    }
    
    func showCurrentLocation() {
        if let userLocation = locationManager.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 400, longitudinalMeters: 400)
            mapView.setRegion(viewRegion, animated: true)
        }
    }
    
    func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.badge, .sound, .alert]) { (granted, error) in
            print ("granted \(granted)")
        }
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
        print("Did Visit")
        sendVisitNotification()
        findNearybSupermarket(visitCoordinate:visit.coordinate)
    }
    
    func findNearybSupermarket(visitCoordinate:CLLocationCoordinate2D) {
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
                var results = [LocationResult]()
                for item in items {
                    let distance = item.placemark.coordinate.distanceTo(otherLocation: visitCoordinate)
                    let result = LocationResult(title: item.name ?? "No Title", distance: distance, isCurrentLocation: item.isCurrentLocation, latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
                    results.append(result)
                    if item.isCurrentLocation {
                        let title = "📍 CURRENT "+(item.name ?? "no name")
                        self.sendVisitNotification(location: result, title:title, body: result.distance.distanceString(), identifier: "currentLocation", interval: 0.5)
                        self.addAnnotation(coordinate: result.locationCoordinate(), title: "📍 IS CURRENT "+result.title)
                    }
                }
                results.sort(by: { (resultA, resultB) -> Bool in
                    return resultA.distance < resultB.distance
                })

                results.sort(by: { (resultA, resultB) -> Bool in
                    return resultA.isCurrentLocation
                })
                
                print("Results \(results.count)")
                
                if let firstLocationResult = results.first {
                    let title = "NEARBY "+firstLocationResult.title
                    self.sendVisitNotification(location: firstLocationResult, title: title, body: firstLocationResult.distance.distanceString(), identifier: "nearbySupermarket", interval: 2)
                    self.addAnnotation(coordinate: firstLocationResult.locationCoordinate(), title: title)
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
        let request = UNNotificationRequest(identifier: "visitDetected", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func sendVisitNotification(location:LocationResult, title:String, body:String, identifier:String, interval:TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = "visitWithMap"
        content.userInfo = ["latitude":location.latitude, "longitude":location.longitude]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
    
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
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

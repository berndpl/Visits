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
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var visitsSwitch: UISwitch!
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
    
    var locationManager:CLLocationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocation()
        setupNotifications()
        
        if let userLocation = locationManager.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 200, longitudinalMeters: 200)
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
        findNearybSupermarket(visitCoordinate:visit.coordinate)
    }
    
    func sendVisitNotification(title:String, body:String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "SupermarketNearby", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
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
                    let result = LocationResult(title: item.name ?? "No Title", distance: distance, isCurrentLocation: item.isCurrentLocation)
                    results.append(result)
                }
                results.sort(by: { (resultA, resultB) -> Bool in
                    return resultA.distance < resultB.distance
                })
                print("Results \(results.count)")
                
                if let firstResult = results.first {
                    var body = ""
                    body.append(firstResult.distance.distanceString())
                    if firstResult.isCurrentLocation {
                        body.append("📍")
                    }
                    self.sendVisitNotification(title: firstResult.title, body: body)
                }
            } else {
              print("No Results")
            }
        }
    }
}

struct LocationResult {
    let title:String
    let distance:Double
    let isCurrentLocation:Bool
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

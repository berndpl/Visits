//
//  NotificationViewController.swift
//  VisitNotification
//
//  Created by Bernd Plontsch on 24.10.18.
//  Copyright © 2018 Bernd Plontsch. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import MapKit
import CoreLocation

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    var locationManager:CLLocationManager = CLLocationManager()
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let size = self.view.bounds
        preferredContentSize = CGSize(width: size.width, height: size.width / 2.0)
    }
    
    func didReceive(_ notification: UNNotification) {
        if let latitude:Double = notification.request.content.userInfo["latitude"] as? Double, let longitude:Double = notification.request.content.userInfo["longitude"] as? Double {
            let location = CLLocationCoordinate2DMake(latitude, longitude)
            self.addAnnotation(coordinate: location, title: notification.request.content.title)
        }
    }
    
    func addAnnotation(coordinate:CLLocationCoordinate2D, title:String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        self.mapView.addAnnotation(annotation)
        self.mapView.showAnnotations([annotation], animated: false)
    }

}

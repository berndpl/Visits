import UIKit
import CoreLocation
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

let results = [LocationResult(title: "1", distance: 0.1, isCurrentLocation: false, latitude: 0.0, longitude: 0.0),
               LocationResult(title: "2", distance: 0.2, isCurrentLocation: false, latitude: 0.0, longitude: 0.0),
               LocationResult(title: "3", distance: 0.3, isCurrentLocation: false, latitude: 0.0, longitude: 0.0),
               LocationResult(title: "4", distance: 0.4, isCurrentLocation: true, latitude: 0.0, longitude: 0.0),
               LocationResult(title: "5", distance: 0.5, isCurrentLocation: false, latitude: 0.0, longitude: 0.0)
]

results


func mapMapItems(items:[MKMapItem])->[LocationResult] {
    var results = [LocationResult]()
    for item in items {
        let distance = 1.0
        let result = LocationResult(title: item.name ?? "No Title", distance: distance, isCurrentLocation: item.isCurrentLocation, latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
        results.append(result)
    }
    return results
}

func sortedResults(results:[LocationResult])->[LocationResult] {
    var results = results
    results.sort(by: { (resultA, resultB) -> Bool in
        return resultA.distance < resultB.distance
    })
    results.sort(by: { (resultA, resultB) -> Bool in
        return resultA.isCurrentLocation
    })
    return results
}

let sorted = sortedResults(results: results)

sorted


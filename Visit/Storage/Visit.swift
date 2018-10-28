//
//  LocationResult.swift
//  Visit
//
//  Created by Bernd Plontsch on 26.10.18.
//  Copyright © 2018 Bernd Plontsch. All rights reserved.
//

import CoreLocation

public struct Visit:Codable {
    let title:String
    let distance:Double
    let date:Date = Date()
    let isCurrentLocation:Bool
    let latitude:Double
    let longitude:Double
    func locationCoordinate()->CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
}


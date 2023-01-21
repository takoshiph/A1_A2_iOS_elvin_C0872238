//
//  LocalityAnnotation.swift
//  Lab Test 1-2
//
//  Created by Elvin Ross Fabella on 2023-01-20.
//

import Foundation
import MapKit

class Annotation: NSObject, MKAnnotation {
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    
    init(title: String? = nil, subtitle: String? = nil, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}
